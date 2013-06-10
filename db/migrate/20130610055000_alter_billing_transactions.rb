class AlterBillingTransactions < ActiveRecord::Migration
  def up    
    remove_column :billing_transactions, :authorization
    remove_column :billing_transactions, :message
    remove_column :billing_transactions, :params

    add_column :billing_transactions, :provider_id, :string
    add_column :billing_transactions, :status, :string
    add_column :billing_transactions, :processor_authorization_code, :string
    add_column :billing_transactions, :processor_response_code, :integer
    add_column :billing_transactions, :processor_response_text, :string
  end

  def down    
    add_column :billing_transactions, :authorization, :string
    add_column :billing_transactions, :message, :string
    add_column :billing_transactions, :params, :string

    remove_column :billing_transactions, :provider_id
    remove_column :billing_transactions, :status
    remove_column :billing_transactions, :processor_authorization_code
    remove_column :billing_transactions, :processor_response_code
    remove_column :billing_transactions, :processor_response_text
  end
end
