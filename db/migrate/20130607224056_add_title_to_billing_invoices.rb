class AddTitleToBillingInvoices < ActiveRecord::Migration
  def change
    add_column :billing_invoices, :title, :string, :null => false
  end
end
