class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :email
      t.string :crypted_password
      t.string :password_salt
      t.string :first_name
      t.string :last_name

      t.string :persistence_token, :null => false
      t.string :perishable_token, :null => false
      t.integer :login_count, :default => 0, :null => false
      
      t.datetime :last_request_at
      
      t.datetime :last_login_at
      t.datetime :current_login_at
      
      t.string :last_login_ip
      t.string :current_login_ip
    end

    add_index :users, :email
    add_index :users, :perishable_token
  end

  def down
    drop_table :users
  end
end
