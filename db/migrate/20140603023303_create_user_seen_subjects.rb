class CreateUserSeenSubjects < ActiveRecord::Migration
  def change
    create_table :user_seen_subjects do |t|
      t.references :user, index: true
      t.references :workflow, index: true
      t.string :subject_zooniverse_ids, array: true

      t.timestamps
    end
  end
end
