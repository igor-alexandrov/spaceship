# coding: UTF-8

class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.login_field = :email

    c.validate_password_field = true
    c.session_ids = [:public]
  end

  attr_accessible :first_name, :last_name, :email, :password, :password_confirmation

  validates :first_name, :presence => true
  validates :last_name, :presence => true  

  has_one :billing_subscription,
    :class_name => 'Billing::Subscription::Base',
    :conditions => proc {
      ["billing_subscriptions.subscription_date <= ? AND (billing_subscriptions.unsubscription_date IS NULL OR billing_subscriptions.unsubscription_date > ?)", Date.today, Date.today]
    },
    :include => :plan,
    :dependent => :destroy

  delegate  :plan, :to => :billing_subscription, :allow_nil => true    

  has_many :billing_invoices, :class_name => 'Billing::Invoice'
  
  attr_accessor :locked_credit

  def invoice!(full_amount, title, options={})
    options.reverse_merge!({
      :params => nil
    })  
    
    self.billing_invoices.create! do |i|
      i.user = self
      i.params = options[:params]      
      i.full_amount = full_amount
      i.title = title
      i.credit_deduction = self.from_credit(full_amount)        
      i.amount = i.full_amount - i.credit_deduction
    end
  end  

  def to_credit(amount)           
    success = transaction do
      self.lock_available_credit!
      self.available_credit += amount.abs      
      self.save(:validate => false)            
    end
    amount = (self.available_credit - self.locked_credit).abs
    
    self.billing_transactions.create(
      :action => 'credit_replenishment',
      :amount => amount,
      :success => success    
    ) if amount != 0       
    
    return amount
  end
  
  def from_credit(amount)        
    success = transaction do
      self.lock_available_credit!
      self.available_credit < amount.abs ? self.available_credit = 0 : self.available_credit -= amount.abs        
      self.save(:validate => false)
    end
    amount = (self.locked_credit - self.available_credit).abs
    
    self.billing_transactions.create(
      :action => 'credit_withdrawal',
      :amount => amount,
      :success => success    
    ) if amount != 0       
    
    return amount
  end

  def subscribed_to?(plan, type)
    self.billing_subscription.present? &&
    self.billing_subscription.plan == plan &&
    self.billing_subscription.class.default_type == type.to_sym
  end

protected
  
  def lock_available_credit!
    self.lock!
    self.locked_credit = self.available_credit
  end

end