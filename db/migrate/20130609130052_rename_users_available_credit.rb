class RenameUsersAvailableCredit < ActiveRecord::Migration
  def up
    rename_column :users, :available_credit, :internal_credit
  end

  def down
    rename_column :users, :internal_credit, :available_credit
  end
end
