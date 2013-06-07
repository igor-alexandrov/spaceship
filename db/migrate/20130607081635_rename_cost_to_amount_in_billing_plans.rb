class RenameCostToAmountInBillingPlans < ActiveRecord::Migration
  def up
    rename_column :billing_plans, :monthly_cost, :monthly_amount
    rename_column :billing_plans, :annual_cost, :annual_amount
  end

  def down
    rename_column :billing_plans, :monthly_amount, :monthly_cost
    rename_column :billing_plans, :annual_amount, :annual_cost
  end
end
