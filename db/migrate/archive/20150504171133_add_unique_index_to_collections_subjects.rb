class AddUniqueIndexToCollectionsSubjects < ActiveRecord::Migration
  def change
    add_column :collections_subjects, :id, :primary_key

    Collection.find_each do |c|
      subjects = c.subjects.uniq
      c.subjects.destroy_all
      c.subjects = subjects
      c.save!
    end

    add_index :collections_subjects, [:collection_id, :subject_id], unique: true
  end
end
