class AddMigratedFlagToSubject < ActiveRecord::Migration
  def change
    add_column :subjects, :migrated, :boolean
  end
end
