class AddExternalLinkToMedium < ActiveRecord::Migration
  def change
    add_column :media, :external_link, :boolean, default: false
  end
end
