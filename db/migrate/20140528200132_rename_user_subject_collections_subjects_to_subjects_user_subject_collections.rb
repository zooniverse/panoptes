class RenameUserSubjectCollectionsSubjectsToSubjectsUserSubjectCollections < ActiveRecord::Migration
  def change
    rename_table :user_subject_collections_subjects, :subjects_user_subject_collections
  end
end
