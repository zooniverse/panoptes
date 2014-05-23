class CreateUserGroups < ActiveRecord::Migration
  def change
    create_table :user_groups do |t|
      t.string :name
      t.string :display_name
      t.integer :classification_count

      t.timestamps
    end
    add_index :user_groups, :name, unique: true
  end
end
