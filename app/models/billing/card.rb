# encoding: utf-8

class Billing::Card < ActiveRecord::Base
  self.table_name = 'billing_cards'
  self.inheritance_column = nil

  belongs_to :user, :inverse_of => :billing_card
  
  attr_accessor :email, :number, :verification_value
  attr_accessible :first_name, :last_name, :credit_card_type, :expiration_date,
  :number, :number_part_1, :number_part_2, :number_part_3, :number_part_4, :verification_value
  
  validates :user, :presence => true
  validates :token, :presence => true
  
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  
  validates :expiration_date, :presence => true
  validates :card_type, :presence => true
  validates :number, :presence => true, :on => :create  
  validates :bin, :presence => true
  
  default_value_for :expiration_date do
    Date.today + 1.month
  end

  scope :expires_in_next_month, lambda {
    where(:expiration_date => Date.today.next_month.beginning_of_month)
  }

  after_initialize do    
    if !self.persisted?
      self.first_name ||= self.user.try(:first_name)
      self.last_name ||= self.user.try(:last_name)
    end
  end

  before_validation(:on => :create) do
    self.create_braintree_card    
  end

  def ensure_braintree_customer_and_save
    if !(self.user.create_braintree_customer && self.user.save)
      self.errors.add(:base, self.user.errors.first)
      return false
    end

    self.save
  end

  (1..4).each do |i|
    define_method("number_part_#{i}") do
      return nil unless self.number.present?
      self.number[4 * (i-1) .. (4 * i) - 1].strip
    end

    define_method("number_part_#{i}=") do |value|
      value << ' ' * (4 - value.length) if value.length < 4

      self.number ||= ' ' * 16
      self.number[4 * (i-1) .. (4 * i) - 1] = value
    end    
  end  
  
protected
  
  def create_braintree_card
    result = Braintree::CreditCard.create(self.braintree_card_fields)
    if result.success?
      self.token = result.credit_card.token
      self.card_type = result.credit_card.card_type
      self.bin = result.credit_card.bin
      self.image_url = result.credit_card.image_url      
    else
      self.errors.add(:base, result.errors.first.message)
      return false
    end
  end

  def braintree_card_fields
    {
      :customer_id => self.user.try(:braintree_customer_id),
      :number => self.number,
      :expiration_date => self.expiration_date.strftime('%m/%Y'),
      :cardholder_name => [self.first_name, self.last_name].compact.join(' ')
    }
  end

end