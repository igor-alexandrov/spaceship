class AddTimestampsToUsers < ActiveRecord::Migration
  def up
    add_column :users, :created_at, :datetime
    add_column :users, :updated_at, :datetime

    execute (<<-EOS)
      UPDATE users SET created_at = NOW()
    EOS
  end

  def down
    remove_column :users, :created_at
    remove_column :users, :updated_at
  end
end
