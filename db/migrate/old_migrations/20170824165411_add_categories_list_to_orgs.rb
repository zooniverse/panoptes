class AddCategoriesListToOrgs < ActiveRecord::Migration
  def change
    add_column :organizations, :categories, :string, array: true, default: []
  end
end
