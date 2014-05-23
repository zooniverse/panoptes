class CreateGroupedSubjects < ActiveRecord::Migration
  def change
    create_table :grouped_subjects do |t|
      t.integer :state
      t.references :subject_group, index: true
      t.integer :classification_count
      t.references :subject, index: true

      t.timestamps
    end
  end
end
