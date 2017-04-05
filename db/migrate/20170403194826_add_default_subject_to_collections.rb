class AddDefaultSubjectToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :default_subject_id, :integer
  end
end
