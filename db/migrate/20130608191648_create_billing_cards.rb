class CreateBillingCards < ActiveRecord::Migration
  def up
    create_table :billing_cards do |t|
      t.integer :user_id, :null => false
      t.string :first_name, :null => false
      t.string :last_name, :null => false
      t.date :expiration_date, :null => false

      t.string :token, :null => false    
      t.string :card_type, :null => false
      t.string :bin, :null => false
      t.string :image_url      
    end

    add_index :billing_cards, :user_id    
  end

  def down
    drop_table :billing_cards
  end
end
