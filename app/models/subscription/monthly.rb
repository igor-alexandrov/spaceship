class Subscription::Monthly < Subscription::Base
  def self.billing_interval(ignore_test_mode = false)
    begin
      Settings.billing.mode == 'test' && !ignore_test_mode ? 2 : 30
    rescue Settingslogic::MissingSetting => e
      30
    end        
  end
  
  def self.default_type
    :monthly
  end
    
  def amount_unspent
    self.calculator.amount_unspent(:monthly)
  end
end