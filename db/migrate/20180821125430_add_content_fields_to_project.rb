class AddContentFieldsToProject < ActiveRecord::Migration
  def change
    add_column :projects, :title, :string
    add_column :projects, :description, :text
    add_column :projects, :introduction, :text
    add_column :projects, :url_labels, :jsonb
    add_column :projects, :workflow_description, :text
    add_column :projects, :researcher_quote, :text
  end
end
