class AddPrimaryLanguageToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :primary_language, :string
  end
end
