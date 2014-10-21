class AddAvatarAndBackgroundImageToProject < ActiveRecord::Migration
  def change
    add_column :projects, :avatar, :text
    add_column :projects, :background_image, :text
  end
end
