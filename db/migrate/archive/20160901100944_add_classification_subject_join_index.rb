class AddClassificationSubjectJoinIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    unless index_exists?(:classification_subjects, :subject_id)
      add_index :classification_subjects, :subject_id, algorithm: :concurrently
    end
  end
end
