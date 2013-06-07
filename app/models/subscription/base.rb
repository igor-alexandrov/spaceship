# coding: UTF-8

class Subscription::Base < ActiveRecord::Base
  belongs_to :user, :inverse_of => :subscription
  belongs_to :plan, :inverse_of => :subscriptions

  delegate :maximum_email_requests_count, :maximum_phone_requests_count, :maximum_developers_count
  
  before_validation :set_billing_dates, :on => :create
  
  validates :type, :presence => true  
  validates :plan, :presence => true  
  validates :user, :presence => true  

  validates :maximum_developers_count, :presence => true
  
  validates :subscription_date, :presence => true
  
  validates :next_billing_date, :presence => true
  # validates_with SubscriptionValidator
  
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
  
  attr_accessible :plan, :user, :trial, :maximum_users_count, :maximum_attorneys_count
  attr_readonly :plan, :user
  
  def self.default_type
    raise NotImplementedError, "Method 'self.default_type' is not implemented"
  end

  def billing_interval(ignore_test_mode = false)
    if self.monthly?
      Subscription::Monthly.billing_interval(ignore_test_mode)
    elsif self.annual?
      Subscription::Annual.billing_interval(ignore_test_mode)
    end
  end

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
    self.forced_type.present? ? self.forced_type == :monthly : self.is_a?(Subscription::Monthly)    
  end
    
  def annual?    
    self.forced_type.present? ? self.forced_type == :annual : self.is_a?(Subscription::Annual)    
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
      self.state_services.not_unsubscribed_at(Date.today).each{ |s| s.cancel!(:date => date, :validate => false) }
      self.additional_services.not_unsubscribed_at(Date.today).each{ |s| s.cancel!(:date => date, :validate => false) }
      self.save
    end    
  end    
  
  def calculator
    @calculator ||= Billing::Subscription::Calculator.new(self)
  end  
  
  delegate :amount, :amount_params, :amount_spent, :amount_spent_params, :to => :calculator

  # State services
  def subscribe_to_state!(state_id)
    service = Billing::StateService.new do |s|
      s.subscription = self
      s.state = State.allowing_liens.find_by_id(state_id)
    end
    
    transaction do  
      service.save!
    
      amount = self.state_service_amount_in(service, Date.today, self.next_billing_date)
      description = service.description(Date.today, self.next_billing_date - 1.day)
    
      self.company.invoice!(amount, description)
    end
    return true   
  end
  
  def unsubscribe_from_state!(state_id)
    service = self.state_services_active_at_today.detect{ |s| s.state_id == state_id.to_i }

    if service.present?
      unsubscription_date = self.trial? ? Date.today : self.next_billing_date
      service.cancel!(:date => unsubscription_date)
    end
    
    return true           
  end

  def subscribed_to_state?(state_or_id)
    state_or_id.is_a?(State) ? self.subscribed_states.include?(state_or_id) : self.subscribed_state_ids.include?(state_or_id.to_i)
  end

  def state_services_active_in(start_date, stop_date)
    key = [start_date.to_time.to_i.to_s, stop_date.to_time.to_i.to_s].join
    @state_services_active_in ||= {}

    return @state_services_active_in[key] if @state_services_active_in[key].present?
    @state_services_active_in[key] = self.state_services.active_in(start_date, stop_date).includes(:state)
  end
  
  def state_services_active_at_today
    return @state_services_active_at_today if defined?(@state_services_active_at_today)
    @state_services_active_at_today ||= self.state_services.active_at(Date.today).includes(:state)
  end
    
  def subscribed_states
    self.state_services_active_at_today.collect{ |s| s.state }.sort_by(&:name)
  end        
  
  def subscribed_state_ids
    self.subscribed_states.collect{ |s| s.id }
  end          

  def can_add_subscribed_states?
    plan.maximum_states_count.blank? || (self.subscribed_states.size < plan.maximum_states_count)
  end
  
  def state_service_amount(service)
    index = self.state_services_active_at_today.index(service) 

    if( index.present? && index >= self.plan.free_states_count )
      service.class.amount(self)
    else
      0
    end
  end

  def state_service_amount_per_day(service)
    self.state_service_amount(service) / self.billing_interval(true)    
  end

  def state_service_amount_in(service, start_date, stop_date)    
    index = self.state_services_active_in(start_date, stop_date).index(service)

    if( index.present? && index >= self.plan.free_states_count )
      (stop_date - start_date).to_i * service.class.amount(self) / self.billing_interval(true)      
    else
      0
    end
  end

  # Additional services
  def subscribe_to_additional_service!(key)
    service = Billing::AdditionalService::Base.visible_children.detect{ |s| s.key == key.to_sym }.new
    service.subscription = self      
    
    transaction do  
      service.save!

      amount = if service.class.billable?
        self.additional_service_amount_in(service, Date.today, self.next_billing_date)
      else
        self.additional_service_amount(service)
      end

      self.company.purchase!(amount, service.description)
    end
    return true   
  end

  def unsubscribe_from_additional_service!(key)
    service = self.additional_services_active_at_today.detect{ |s| s.class.key == key.to_sym }        
    service.cancel!(:date => self.next_billing_date) if service.present?    
    
    return true           
  end

  def subscribed_to_additional_service?(service_or_key)
    service_or_key.is_a?(Billing::AdditionalService::Base) ? self.subscribed_additional_services.include?(service_or_key) : self.subscribed_additional_service_keys.include?(service_or_key)
  end

  def additional_services_active_in(start_date, stop_date)
    key = [start_date.to_time.to_i.to_s, stop_date.to_time.to_i.to_s].join
    @additional_services_active_in ||= {}

    return @additional_services_active_in[key] if @additional_services_active_in[key].present?
    @additional_services_active_in[key] = self.additional_services.active_in(start_date, stop_date)
  end
  
  def additional_services_active_at_today
    return @additional_services_active_at_today if defined?(@additional_services_active_at_today)
    @additional_services_active_at_today ||= self.additional_services.active_at(Date.today)
  end
    
  def subscribed_additional_services
    self.additional_services_active_at_today.collect{ |s| s.class }
  end        
  
  def subscribed_additional_service_keys
    self.additional_services_active_at_today.collect{ |s| s.class.key }
  end

  def additional_service_amount(service)    
    service.class.amount(self)    
  end

  def additional_service_amount_per_day(service)
    self.additional_service_amount(service) / self.billing_interval(true)    
  end

  def additional_service_amount_in(service, start_date, stop_date)        
    (stop_date - start_date).to_i * self.additional_service_amount_per_day(service)    
  end

  # Attorneys
  def attorneys_amount_per_day
    self.attorneys_amount / self.billing_interval(true)    
  end

  def attorneys_amount_in(start_date, stop_date)
    return (stop_date - start_date).to_i * self.attorneys_amount_per_day
  end

  def inherit!(subscription)    
    self.maximum_users_count = subscription.maximum_users_count    
    self.maximum_attorneys_count = subscription.maximum_attorneys_count    

    if self.is_a?(subscription.class)
      self.next_percentage_discount = subscription.next_percentage_discount
      self.next_dollar_discount = subscription.next_dollar_discount
      self.next_discounts_count = subscription.next_discounts_count
    end

    if subscription.trial?
      self.next_billing_date = subscription.next_billing_date
      self.trial = true
    end

    self.inherit_state_services!(subscription)
    self.inherit_additional_services!(subscription)
  end
  
  def force_state_services!
    self.state_services.each{ |s| s.forced! }
  end

  def with_disabled_paper_trail_for_services(&block)
    Billing::StateService.paper_trail_off
    Billing::AdditionalService::Base.paper_trail_off

    yield self if block_given?

    Billing::StateService.paper_trail_on
    Billing::AdditionalService::Base.paper_trail_on
  end
  
  def next_discounts_count=(value)
    value = nil if value.present? && value.to_i < 1
    write_attribute(:next_discounts_count, value)
  end

protected
  
  def inherit_state_services!(subscription)      
    services = subscription.state_services.not_unsubscribed_at(Date.today).map do |s|
      service = s.dup
      service.subscription = nil
      service      
    end
    self.state_services = services 
  end

  def inherit_additional_services!(subscription)
    services = subscription.additional_services.not_unsubscribed_at(Date.today).map do |s|
      service = s.dup
      service.subscription = nil
      service      
    end

    services += self.plan.required_additional_services.map { |s| s.new } if self.plan.present?    
    services.flatten!

    self.additional_services = services
  end
  
  def set_billing_dates
    if self.new_record?      
      # set next billing date only if it is not predefined
      if self.next_billing_date.nil?
        self.next_billing_date = ((self.plan.present? && self.trial) ? self.subscription_date + self.plan.trial.days : self.subscription_date)
      end
    else
      self.previous_billing_date = self.next_billing_date
      self.next_billing_date = self.next_billing_date + self.billing_interval.days
    end
  end  

  def set_discounts
    self.percentage_discount = self.next_percentage_discount
    self.dollar_discount = self.next_dollar_discount

    if self.next_discounts_count.present? && self.next_discounts_count > 1
      self.next_discounts_count -= 1
    else
      self.next_percentage_discount = nil
      self.next_dollar_discount = nil
      self.next_discounts_count = nil
    end
  end
end