class AddContentFieldsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :description, :string
    add_column :organizations, :introduction, :text
    add_column :organizations, :url_labels, :jsonb
    add_column :organizations, :announcement, :string
  end
end
