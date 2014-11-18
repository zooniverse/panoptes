class AddMetadataToSubjectSets < ActiveRecord::Migration
  def change
    add_column :subject_sets, :metadata, :json
  end
end
