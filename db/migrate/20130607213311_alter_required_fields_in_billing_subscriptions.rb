class AlterRequiredFieldsInBillingSubscriptions < ActiveRecord::Migration
  def up
    change_column_null :billing_subscriptions, :type, false
    change_column_null :billing_subscriptions, :user_id, false
    change_column_null :billing_subscriptions, :plan_id, :integer, false
    change_column_null :billing_subscriptions, :developers_count, false
    change_column_default :billing_subscriptions, :developers_count, 1
    execute (<<-EOS)
      ALTER TABLE "billing_subscriptions" ALTER COLUMN "trial" TYPE boolean USING CASE WHEN "trial" = 0 THEN FALSE ELSE TRUE END
    EOS
    change_column_null :billing_subscriptions, :trial, false
    change_column_default :billing_subscriptions, :trial, false
    change_column_null :billing_subscriptions, :subscription_date, false
    change_column_null :billing_subscriptions, :next_billing_date, false
  end

  def down
    change_column_null :billing_subscriptions, :type, true
    change_column_null :billing_subscriptions, :user_id, true
    change_column_null :billing_subscriptions, :plan_id, true
    change_column_null :billing_subscriptions, :developers_count, true
    change_column_default :billing_subscriptions, :developers_count, nil
    execute (<<-EOS)
      ALTER TABLE "billing_subscriptions" ALTER COLUMN "trial" TYPE integer USING CASE WHEN "trial" = false THEN 0 ELSE 1 END
    EOS
    change_column_null :billing_subscriptions, :trial, true
    change_column_default :billing_subscriptions, :trial, nil
    change_column_null :billing_subscriptions, :subscription_date, true
    change_column_null :billing_subscriptions, :next_billing_date, true
  end
end
