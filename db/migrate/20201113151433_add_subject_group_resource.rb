class AddSubjectGroupResource < ActiveRecord::Migration
  def change
    create_table :subject_groups do |t|
      # record any contextual information, e.g. subject selection
      t.jsonb :context, null: false, default: {}
      # record a key of subject ids that make up this group
      t.string :key, null: false, index: true

      # record which project the subject group belongs to
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
