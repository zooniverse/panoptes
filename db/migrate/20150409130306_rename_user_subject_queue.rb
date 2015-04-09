class RenameUserSubjectQueue < ActiveRecord::Migration
  def change
    rename_table :user_subject_queues, :subject_queues
    rename_column :subject_queues, :subject_ids, :set_member_subject_ids
    add_column :subject_queues, :subject_set_id, :integer, references: :subject_set
  end
end
