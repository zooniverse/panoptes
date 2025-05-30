class AddProjectIdIdIndexToSubjects < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :subjects, %i[project_id id], name: 'idx_subjects_project_id_id', algorithm: :concurrently
  end
end
