class AddUnsubscribeTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :unsubscribe_token, :string, null: false
    add_index  :users, :unsubscribe_token, unique: true
  end
end
