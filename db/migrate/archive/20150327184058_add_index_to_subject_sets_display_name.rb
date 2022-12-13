class AddIndexToSubjectSetsDisplayName < ActiveRecord::Migration
  def change
    remove_index :subject_sets, :project_id
    add_index :subject_sets, [:project_id, :display_name]
  end
end
