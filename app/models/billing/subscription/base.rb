# coding: UTF-8

class Billing::Subscription::Base < ActiveRecord::Base
  include Models::BooleanAccessor

  self.table_name = 'billing_subscriptions'

  belongs_to :user, :inverse_of => :billing_subscription
  belongs_to :plan, :inverse_of => :subscriptions, :class_name => 'Billing::Plan'

  delegate :maximum_email_requests_count, :maximum_phone_calls_count, :maximum_developers_count, :to => :plan
  
  before_validation :set_billing_dates, :on => :create
  
  validates :type, :presence => true  
  validates :plan, :presence => true  
  validates :user, :presence => true  

  validates :developers_count, :presence => true
  
  validates :subscription_date, :presence => true
  
  validates :next_billing_date, :presence => true

  validates_with Billing::SubscriptionValidator
  
  default_value_for :subscription_date do 
    Date.today
  end
  
  default_scope order(:subscription_date.desc)
  
  scope :active, where("subscriptions.subscription_date <= ? AND (subscriptions.unsubscription_date IS NULL OR subscriptions.unsubscription_date > ?)", Date.today, Date.today)    
  scope :should_be_billed, where("( subscriptions.next_billing_date <= ? ) AND (subscriptions.unsubscription_date IS NULL)", Date.today)

  scope :with_elapsing_trial, lambda { |days = 0|
    where{
      (trial == true) &
      (next_billing_date == Date.today + days) &
      (unsubscription_date == nil)
    }
  }
  
  attr_accessible :trial, :developers_count, :plan_key

  attr_readonly :plan, :user, :developers_count

  boolean_accessor :forced
  
  def self.default_type
    raise NotImplementedError, "Method 'self.default_type' is not implemented"
  end

  def self.build(params = {})    
    !params.nil? && params.delete(:type) == 'annual' ? Billing::Subscription::Annual.new(params) : Billing::Subscription::Monthly.new(params)      
  end

  def plan_key=(value)
    self.plan = Billing::Plan.find_by_key(value)
  end

  def subscribe(user, options = {})
    options.reverse_merge!({
      :refund => true
    })

    transaction do      
      self.inherit(user)

      if user.billing_subscription.present?          
        raise ActiveRecord::Rollback if !user.billing_subscription.cancel(Date.today, :refund => options[:refund])
      end

      self.user = user

      self.save!
      self.bill unless self.trial?
      return true
    end

  rescue => e
    puts e.message
    puts e.backtrace

    user.reload
    return false
  end

  def billing_interval(ignore_test_mode = false)
    if self.monthly?
      Billing::Subscription::Monthly.billing_interval(ignore_test_mode)
    elsif self.annual?
      Billing::Subscription::Annual.billing_interval(ignore_test_mode)
    end
  end

  attr_reader :forced_type

  def force_type(type, &block)    
    @forced_type = type
    value = yield self if block_given?
    @forced_type = nil

    return value
  end

  def ignore_trial(&block)
    @ignore_trial = true
    value = yield self if block_given?
    @ignore_trial = false

    return value
  end

  def ignore_trial?
    @ignore_trial || false
  end
  
  def monthly?
    self.forced_type.present? ? self.forced_type == :monthly : self.is_a?(Billing::Subscription::Monthly)    
  end
    
  def annual?    
    self.forced_type.present? ? self.forced_type == :annual : self.is_a?(Billing::Subscription::Annual)    
  end    
          
  def amount_unspent
    raise NotImplementedError, "Method 'amount_unspent' is not implemented"  
  end
  
  def previous_action_date
    self.previous_billing_date || self.subscription_date
  end
  
  def days
    (self.next_billing_date - self.previous_action_date).to_i
  end
  
  def days_spent
    (Date.today - self.previous_action_date).to_i
  end
  
  def days_unspent
    (self.next_billing_date - Date.today).to_i
  end    
  
  def bill_async
    Delayed::Job.enqueue(SubscriptionBillJob.new(self.id))
  end
  
  def bill(options={})    
    if (self.next_billing_date <= Date.today) && (self.unsubscription_date.nil? || self.unsubscription_date > Date.today) 

      if self.trial?
        self.trial = false
        self.save!
      end
          
      self.class.transaction do        
        self.set_billing_dates

        title = "JetRockets magic #{self.previous_billing_date.strftime('%e %b %Y')} — #{(self.next_billing_date - 1.day).strftime('%e %b %Y')}"        
        self.user.invoice!(self.amount, title, { :params => self.amount_params })
        
        self.billed_at = Time.now
        self.save!
      end
    else
      true
    end
  end
  
  def cancel(date = Date.today, options = {})
    options.reverse_merge!({
      :refund => false
    })
    
    date = Date.today if date < Date.today
    transaction do
      self.user.to_credit(self.amount_unspent) if options[:refund]
      self.unsubscription_date = date      
      # self.additional_services.not_unsubscribed_at(Date.today).each{ |s| s.cancel!(:date => date, :validate => false) }
      self.save
    end    
  end    
  
  def calculator
    @calculator ||= Spaceship::Billing::SubscriptionCalculator.new(self)
  end  
  
  delegate :amount, :amount_params, :amount_spent, :amount_spent_params, :to => :calculator

  def inherit(user)    
    current_subscription = user.billing_subscription

    if self.plan.present?
      self.trial = (current_subscription.blank? || (current_subscription.present? && current_subscription.trial?)) && self.plan.present? && self.plan.trial > 0  
    end

    return if current_subscription.blank?

    self.developers_count ||= current_subscription.developers_count        
    # self.next_billing_date = current_subscription.next_billing_date if subscription.trial?
    
    # self.inherit_additional_services!(subscription)
  end

protected
  
  def set_billing_dates
    if self.new_record?      
      # set next billing date only if it is not predefined
      if self.next_billing_date.nil?
        self.next_billing_date = ((self.plan.present? && self.trial?) ? self.subscription_date + self.plan.trial.days : self.subscription_date)
      end
    else
      self.previous_billing_date = self.next_billing_date
      self.next_billing_date = self.next_billing_date + self.billing_interval.days
    end
  end
end