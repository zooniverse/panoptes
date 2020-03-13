class AddSubjectGroupModel < ActiveRecord::Migration
  def change
    create_table :subject_groups do |t|
      # I think we will need to record the specific ordering of the subjects
      t.integer :ordered_subject_ids, array: true, default: [], null: false

      # what else about the 'Group' will need to be recorded to understand the
      # selection, creation and classification events?

      # record which project the subject group belongs to
      # I can't see us querying the Project.subject_groups relation
      # so i don't think we will need an index on this
      t.references :project, foreign_key: true, null: false

      t.timestamps null: false
    end

    create_join_table :subjects, :subject_groups do |t|
      t.references :subject, index: true, foreign_key: true
      t.references :subject_group, index: true, foreign_key: true
    end
  end
end