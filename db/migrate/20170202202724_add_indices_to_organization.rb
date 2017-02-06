class AddIndicesToOrganization < ActiveRecord::Migration
  def change
    add_index :organizations, :updated_at
    add_index :organizations, :display_name
  end
end
