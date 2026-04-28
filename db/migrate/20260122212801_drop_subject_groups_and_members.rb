class DropSubjectGroupsAndMembers < ActiveRecord::Migration[7.0]
  def up
    drop_table :subject_group_members, if_exists: true
    drop_table :subject_groups, if_exists: true
  end

  def down
    create_table :subject_groups do |t|
      t.jsonb :context, default: {}, null: false
      t.string :key, null: false
      t.integer :project_id, null: false
      t.integer :group_subject_id, null: false
      t.timestamps null: false
    end

    create_table :subject_group_members do |t|
      t.integer :subject_group_id
      t.integer :subject_id
      t.integer :display_order, null: false
      t.timestamps
    end

    add_index :subject_groups, :key, unique: true
    add_index :subject_group_members, :subject_group_id
    add_index :subject_group_members, :subject_id

    add_foreign_key :subject_groups, :projects
    add_foreign_key :subject_groups, :subjects, column: :group_subject_id
    add_foreign_key :subject_group_members, :subjects
    add_foreign_key :subject_group_members, :subject_groups
  end
end
