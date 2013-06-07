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
    :dependent => :destroy,
    :inverse_of => :user

  delegate  :plan, :to => :billing_subscription, :allow_nil => true    

  has_many :billing_invoices, :class_name => 'Billing::Invoice'
  
  def subscribe_to(plan, options = {})    
    options.reverse_merge!({
      :type         => :monthly,
      :trial        => false,
      :forced       => false,
      :refund       => true
    })
    
    case options[:type].to_sym
    when :annual
      subscription = Billing::Subscription::Annual.new(:plan => plan, :user_id => self.id)
    else
      subscription = Billing::Subscription::Monthly.new(:plan => plan, :user_id => self.id)
    end    
    subscription.forced! if options[:forced]
    subscription.inherit!(self.billing_subscription) if self.billing_subscription.present?    
    subscription.developers_count = options[:developers_count] if options[:developers_count].present?    

    return false if subscription.invalid?
    
    begin
      transaction do
        if self.billing_subscription.present?          
          raise ActiveRecord::Rollback if !self.billing_subscription.cancel(Date.today, :refund => options[:refund])
        end

        subscription.save!        
      end
    rescue => e      
      return false
    end      
    subscription.bill(:current_user => options[:current_user]) unless subscription.trial?    
    
    return true
  end  
end