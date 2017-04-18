class AddDefaultSubjectToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :default_subject_id, :integer
    add_foreign_key :collections, :subjects, column: :default_subject_id
  end
end
