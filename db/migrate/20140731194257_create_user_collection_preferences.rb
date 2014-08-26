class CreateUserCollectionPreferences < ActiveRecord::Migration
  def change
    create_table :user_collection_preferences do |t|
      t.json :preferences
      t.string :roles, array: true, default: [], null: false
      t.references :user, index: true
      t.references :collection, index: true

      t.timestamps
    end
  end
end
