class Billing::Transaction < ActiveRecord::Base
  self.table_name = 'billing_transactions'
  self.per_page = 10
  
  ACTIONS = ['braintree_payment', 'internal_credit_replenishment', 'internal_credit_withdrawal']

  belongs_to :user
  belongs_to :invoice, :class_name => "Billing::Invoice"
  belongs_to :card, :class_name => "Billing::Card"
  serialize :params
    
  validates :amount,
    :presence => true,
    :numericality => {
      :greater_than_or_equal_to => 0
    }

  validates :user, :presence => true

  validates :action, :inclusion => { :in => ACTIONS }
  
  attr_readonly :user, :invoice, :action, :amount, :success
  attr_accessible :invoice, :action, :amount
  
  scope :recent, lambda{ |count| order('created_at DESC').limit(count) }

  before_validation(:on => :create) do
    if self.payment?
      self.create_braintree_transaction
    end
  end

  # after_commit(:on => :create) do
  #   if self.payment? && self.success?
  #     Billing::Notifier.payment_receipt(self).deliver
  #   end
  # end
  
  def payment?
    ['braintree_payment'].include?(self.action)
  end

  def received_amount
    if payment?
      return 0.971 * amount - 0.3 if amount > 0.3
    end
  end

protected

  def create_braintree_transaction
    result = Braintree::Transaction.sale(
      :amount => self.amount,
      :customer_id => self.user.try(:braintree_customer_id),
      :payment_method_token => self.user.try(:billing_card).try(:token),
      :options => {
        :submit_for_settlement => true
      }
    )

    self.provider_id = result.transaction.id
    self.status = result.transaction.status
    self.processor_authorization_code = result.transaction.processor_authorization_code
    self.processor_response_code = result.transaction.processor_response_code
    self.processor_response_text = result.transaction.processor_response_text            
    self.success = (self.processor_response_code == 1000)
    
    self.errors.add(:base, result.errors.first.message) if !result.success? && result.errors.any?
  end
end