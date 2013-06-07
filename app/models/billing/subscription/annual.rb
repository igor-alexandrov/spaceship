class Billing::Subscription::Annual < Billing::Subscription::Base
  def self.billing_interval(ignore_test_mode = false)
    begin
      Settings.billing.mode == 'test' && !ignore_test_mode ? 3 : 365
    rescue Settingslogic::MissingSetting => e
      365
    end    
  end
  
  def self.default_type
    :annual
  end
      
  def amount_unspent
    self.calculator.amount_unspent(:monthly)
  end
end