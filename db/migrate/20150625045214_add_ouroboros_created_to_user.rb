class AddOuroborosCreatedToUser < ActiveRecord::Migration
  def change
    add_column :users, :ouroboros_created, :boolean, default: false
  end
end
