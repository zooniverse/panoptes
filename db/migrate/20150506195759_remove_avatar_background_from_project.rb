class RemoveAvatarBackgroundFromProject < ActiveRecord::Migration
  def change
    remove_column :projects, :avatar, :text
    remove_column :projects, :background_image, :text
  end
end
