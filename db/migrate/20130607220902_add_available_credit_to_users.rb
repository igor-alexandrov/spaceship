class AddAvailableCreditToUsers < ActiveRecord::Migration
  def change
    add_column :users, :available_credit, :decimal, :precision => 8, :scale => 2, :null => false, :default => 0
  end
end
