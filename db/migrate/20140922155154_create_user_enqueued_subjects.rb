class CreateUserEnqueuedSubjects < ActiveRecord::Migration
  def change
    create_table :user_enqueued_subjects do |t|
      t.references :user, index: true
      t.references :workflow, index: true
      t.integer :subject_ids, array: true, default: [], null: false

      t.timestamps
    end
  end
end
