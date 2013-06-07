class CreateBillingSubscriptions < ActiveRecord::Migration
  def up
    create_table :billing_subscriptions do |t|
      t.string :type
      t.integer :user_id
      t.integer :plan_id
      t.integer :developers_count
      t.integer :trial

      t.date :subscription_date
      t.date :unsubscription_date
      t.timestamp :billed_at
      t.date :previous_billing_date
      t.date :next_billing_date
          
      t.timestamps
    end
        
    add_index :billing_subscriptions, :user_id
  end

  def down
    drop_table :billing_subscriptions
  end
end
