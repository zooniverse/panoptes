class ForeignKeysCollectionsSubjects < ActiveRecord::Migration
  def change
    CollectionsSubject.joins("LEFT OUTER JOIN subjects ON subjects.id = collections_subjects.subject_id").where("collections_subjects.subject_id IS NOT NULL AND subjects.id IS NULL").delete_all
    CollectionsSubject.joins("LEFT OUTER JOIN collections ON collections.id = collections_subjects.collection_id").where("collections_subjects.collection_id IS NOT NULL AND collections.id IS NULL").delete_all
    add_foreign_key :collections_subjects, :subjects, on_update: :cascade, on_delete: :restrict
    add_foreign_key :collections_subjects, :collections, on_update: :cascade, on_delete: :cascade
  end
end
