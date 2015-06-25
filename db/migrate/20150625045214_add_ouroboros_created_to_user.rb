class AddOuroborosCreatedToUser < ActiveRecord::Migration
  def change
    add_column :users, :ouroboros_created, :boolean
  end
end
