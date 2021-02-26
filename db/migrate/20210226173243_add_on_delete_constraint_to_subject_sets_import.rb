class AddOnDeleteConstraintToSubjectSetsImport < ActiveRecord::Migration
  def change
    remove_foreign_key :subject_set_imports, :subject_sets
    add_foreign_key :subject_set_imports, :subject_sets, on_update: :cascade, on_delete: :cascade, validate: false
  end
end
