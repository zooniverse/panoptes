class ForeignKeysSubjectSets < ActiveRecord::Migration
  def change
    subject_set_ids = SubjectSet.joins("LEFT OUTER JOIN projects ON projects.id = subject_sets.project_id").where("subject_sets.project_id IS NOT NULL AND projects.id IS NULL").pluck("subject_sets.id")
    SubjectSetsWorkflow.where(subject_set_id: subject_set_ids).delete_all
    SubjectSet.where(id: subject_set_ids).delete_all
    add_foreign_key :subject_sets, :projects, on_update: :cascade, on_delete: :cascade
  end
end
