class CreateSubjects < ActiveRecord::Migration
  def change
    create_table :subjects do |t|
      t.string :zooniverse_id
      t.json :metadata
      t.json :locations

      t.timestamps
    end
    add_index :subjects, :zooniverse_id, unique: true
  end
end
