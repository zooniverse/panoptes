class RemoveClassificationIndexes < ActiveRecord::Migration
  def change
    # don't revert these, add a new migration and build the indexes concurrently!
    remove_index :classifications, column: :created_at
    remove_index :classifications, column: :lifecycled_at
    # this should be added back in for the created_by scope
    remove_index :classifications, column: :user_id

    # no subjects -> classifications association
    remove_index :classification_subjects, column: :subject_id
  end
end
