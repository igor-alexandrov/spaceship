class CreateBillingInvoices < ActiveRecord::Migration
  def up
    create_table :billing_invoices do |t|
      t.integer :user_id

      t.decimal :full_amount, :precision => 8, :scale => 2
      t.decimal :credit_deduction, :precision => 8, :scale => 2
      t.decimal :amount, :precision => 8, :scale => 2
            
      t.text :params

      t.timestamp :paid_at
      t.date :issue_date
      t.date :due_date
      
      t.timestamps
    end

    add_index :billing_invoices, :user_id
    add_index :billing_invoices, :issue_date
    add_index :billing_invoices, :due_date
  end

  def down
    drop_table :billing_invoices
  end
end
