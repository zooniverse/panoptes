class RemoveAvatarFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :avatar, :text
  end
end
