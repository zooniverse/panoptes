class ModifyCollectionsSubjectsIndex < ActiveRecord::Migration
  def change
    add_index :collections_subjects, :subject_id
  end
end
