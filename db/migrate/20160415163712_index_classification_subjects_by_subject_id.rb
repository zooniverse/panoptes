class IndexClassificationSubjectsBySubjectId < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :classification_subjects, :subject_id, algorithm: :concurrently
  end
end
