class RenameMaximumPhoneRequestsInBillingPlans < ActiveRecord::Migration
  def up
    rename_column :billing_plans, :maximum_phone_requests_count, :maximum_phone_calls_count
  end

  def down
    rename_column :billing_plans, :maximum_phone_calls_count, :maximum_phone_requests_count
  end
end
