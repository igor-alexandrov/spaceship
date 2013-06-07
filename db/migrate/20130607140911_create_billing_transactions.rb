class CreateBillingTransactions < ActiveRecord::Migration
  def up    
    create_table :billing_transactions do |t|
      t.integer :user_id
      t.integer :invoice_id
      t.integer :card_id

      t.string :action
      t.decimal :amount, :precision => 8, :scale => 2

      t.boolean :success
      t.string :authorization
      t.string :message
      t.text :params

      t.boolean :refunded

      t.timestamps
    end
    
    add_index :billing_transactions, :user_id
    add_index :billing_transactions, :invoice_id
    add_index :billing_transactions, :card_id    
  end

  def down
    drop_table :billing_transactions
  end
end
