# coding: UTF-8

class Billing::Plan < ActiveRecord::Base
  self.table_name = 'billing_plans'

  validates :title, :presence => true
  validates :key, :presence => true, :uniqueness => true

  validates :monthly_amount,  :presence => { :unless => :free? },
                              :absence => { :if => :free? },
                              :numericality => { :allow_nil => true, :greater_than_or_equal_to => 0 }
                              
  validates :annual_amount,   :presence => { :unless => :free? },
                              :absence => { :if => :free? },
                              :numericality => { :allow_nil => true, :greater_than_or_equal_to => 0 }

  validates :trial, :presence => true, :numericality => { :greater_than_or_equal_to => 0 }
  
  validates :maximum_email_requests_count, :numericality => { :greater_or_equal_than => 0, :allow_nil => true }
  validates :maximum_phone_requests_count, :numericality => { :greater_or_equal_than => 0, :allow_nil => true }
  
  validates :maximum_developers_count, :presence => true, :numericality => { :greater_than => 0 }
  
  attr_accessible :key, :title, :monthly_amount, :annual_amount, :trial, :maximum_email_requests_count, :maximum_phone_requests_count, :maximum_developers_count

  def amount(subscription)
    return 0 if subscription.trial? && !subscription.ignore_trial?
    
    if subscription.monthly?
      return (self.monthly_amount || 0.0) * subscription.developers_count
    elsif subscription.annual?
      return (self.annual_amount || 0.0) * subscription.developers_count
    end
  end

  def amount_per_day(subscription)
    self.amount(subscription) / subscription.billing_interval(true)
  end

  def amount_in(subscription, start_date, stop_date)
    return ((stop_date - start_date).to_i * self.amount_per_day(subscription))
  end

  def to_param
    self.key
  end

  def trial(ignore_test_mode = false)
    value = self.read_attribute(:trial)

    test_mode = Settings.billing.mode == 'test' && value != 0 && !ignore_test_mode rescue false
    test_mode ? 2 : value    
  end
end
