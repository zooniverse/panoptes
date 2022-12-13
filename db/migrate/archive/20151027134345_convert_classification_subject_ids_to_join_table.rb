class ConvertClassificationSubjectIdsToJoinTable < ActiveRecord::Migration
  def change
    create_table :classification_subjects, id: false do |t|
      t.integer :classification_id, null: false
      t.integer :subject_id, null: false
    end

    add_index :classification_subjects, [:classification_id, :subject_id], unique: true, name: 'classification_subjects_pk'
    add_index :classification_subjects, :classification_id
    add_index :classification_subjects, :subject_id
    add_foreign_key :classification_subjects, :classifications
    add_foreign_key :classification_subjects, :subjects
  end
end
