class ForeignKeysSetMemberSubjects < ActiveRecord::Migration
  def change
    SetMemberSubject.joins("LEFT OUTER JOIN subject_sets ON subject_sets.id = set_member_subjects.subject_set_id").where("set_member_subjects.subject_set_id IS NOT NULL AND subject_sets.id IS NULL").delete_all
    SetMemberSubject.joins("LEFT OUTER JOIN subjects ON subjects.id = set_member_subjects.subject_id").where("set_member_subjects.subject_id IS NOT NULL AND subjects.id IS NULL").delete_all
    add_foreign_key :set_member_subjects, :subject_sets, on_update: :cascade, on_delete: :cascade
    add_foreign_key :set_member_subjects, :subjects, on_update: :cascade, on_delete: :cascade
  end
end
