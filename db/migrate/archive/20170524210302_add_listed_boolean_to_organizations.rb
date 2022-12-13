class AddListedBooleanToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :listed, :boolean, index: true, default: false, null: false
  end
end
