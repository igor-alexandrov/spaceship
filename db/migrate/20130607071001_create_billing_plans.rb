class CreateBillingPlans < ActiveRecord::Migration
  def up
    create_table :billing_plans do |t|
      t.string  :title
      t.string  :key
      
      t.decimal :monthly_cost, :precision => 8, :scale => 2
      t.decimal :annual_cost, :precision => 8, :scale => 2      
      
      t.integer :trial

      t.integer :maximum_email_requests_count
      t.integer :maximum_phone_requests_count

      t.integer :maximum_developers_count
          
      t.timestamps
    end
    
    add_index :billing_plans, :key, :unique => true
  end

  def down
    drop_table :billing_plans
  end
end
