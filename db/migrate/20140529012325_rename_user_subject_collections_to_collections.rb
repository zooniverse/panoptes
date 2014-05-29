class RenameUserSubjectCollectionsToCollections < ActiveRecord::Migration
  def change
    rename_table :user_subject_collections, :collections
    rename_table :subjects_user_subject_collections, :collections_subjects
    rename_column :collections_subjects, :user_subject_collection_id, :collection_id
  end
end
