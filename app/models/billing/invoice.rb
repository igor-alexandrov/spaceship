# encoding: utf-8

class Billing::Invoice < ActiveRecord::Base
  self.table_name = "billing_invoices"
  default_scope order('billing_invoices.issue_date DESC, billing_invoices.created_at DESC')  
    
  self.per_page = 10
    
  belongs_to :user, :inverse_of => :billing_transactions
  
  has_many :transactions, :class_name => "Billing::Transaction"
  has_one :successful_transactions, :class_name => "Billing::Transaction", :conditions => { :success => true }
  
  attr_readonly :full_amount, :amount, :credit_deduction, :percentage_discount, :dollar_discount

  serialize :params  
  
  validates :amount, :full_amount,
    :presence => true,
    :numericality => {
      :greater_than_or_equal_to => 0
    }
  
  validates :credit_deduction,
    :numericality => {
      :greater_than_or_equal_to => 0
    }
  
  
  # default values
  default_value_for :issue_date do
    Date.today
  end
  
  default_value_for :due_date do
    Date.today + 10.days
  end  
  
  scope :unpaid, where(:paid_at.eq => nil)
  scope :paid, where(:paid_at.not_eq => nil)
  
  scope :overdue_in, lambda { |days = 0.days|
    where{
      (paid_at == nil) & (due_date < Date.today + days)
    }
  }
  scope :overdue, overdue_in
  
  before_validation(:on => :create) do
    self.full_amount = 0 if self.full_amount.present? && self.full_amount < 0
    self.amount = 0 if self.amount.present? && self.amount < 0
    self.credit_deduction = 0 if self.credit_deduction.present? && self.credit_deduction < 0    
  end

  after_create do    
    if self.zero?
      self.paid!
    else      
      self.pay_async
    end
  end

  after_commit(:on => :create) do
    Billing::Notifier.invoice_created(self).deliver rescue StandardError unless self.zero?    
  end
  
  def zero?
    self.amount == 0
  end

  def paid?
    self.paid_at.present?
  end
  
  def unpaid?
    !self.paid?
  end
  
  def paid!(time = Time.now)
    self.paid_at = time
    self.save!
  end

  def pay_async
    return true if self.paid?

    # Delayed::Job.enqueue(Billing::InvoicePayJob.new(self.id), :priority => 10, :run_at => 1.hour.from_now, :queue => 'billing')
  end

  def pay!(options = {})
    return true if self.paid?

    begin    
      transaction = self.user.purchase!(self)
      raise RuntimeError.new("(#{transaction.processor_response_code}) #{transaction.processor_response_text}") if !transaction.success?

      self.paid!
    rescue StandardError => e
      self.user.void(transaction) if transaction.success?
      raise
    end
  end  
      
  def amount_as_cents
    self.amount * 100
  end
end
