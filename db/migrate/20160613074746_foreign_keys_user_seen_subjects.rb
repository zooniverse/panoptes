class ForeignKeysUserSeenSubjects < ActiveRecord::Migration
  def change
    UserSeenSubject.joins("LEFT OUTER JOIN workflows ON workflows.id = user_seen_subjects.workflow_id").where("user_seen_subjects.workflow_id IS NOT NULL AND workflows.id IS NULL").delete_all
    add_foreign_key :user_seen_subjects, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :user_seen_subjects, :workflows, on_update: :cascade, on_delete: :cascade
  end
end
