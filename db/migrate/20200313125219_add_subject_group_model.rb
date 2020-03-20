# frozen_string_literal: true

class AddSubjectGroupModel < ActiveRecord::Migration
  def change
    create_table :subject_groups do |t|
      # what else about the 'Group' will need to be recorded to understand the
      # selection, creation and classification events for hte 'group' of subjects?

      # record which project the subject group belongs to
      # I can't see us querying the Project.subject_groups relation
      # so i don't think we will need an index on this
      t.references :project, foreign_key: true, null: false

      t.timestamps null: false
    end

    create_table :subject_group_members do |t|
      t.references :subject_group, index: true, foreign_key: true
      t.references :subject, index: true, foreign_key: true
      # record what position in the group the subject will be displayed
      t.integer :display_order, null: false

      t.timestamps
    end
  end
end
