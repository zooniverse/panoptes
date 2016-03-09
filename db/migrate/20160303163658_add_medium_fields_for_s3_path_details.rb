class AddMediumFieldsForS3PathDetails < ActiveRecord::Migration
  def change
    add_column :media, :content_disposition, :string
  end
end
