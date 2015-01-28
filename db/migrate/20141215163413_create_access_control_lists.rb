class CreateAccessControlLists < ActiveRecord::Migration
  def change
    create_table :access_control_lists do |t|
      t.references :user_group, index: true
      t.string :roles, array: true, default: [], null: false
      t.references :resource, polymorphic: true, index: true

      t.timestamps
    end
  end
end
