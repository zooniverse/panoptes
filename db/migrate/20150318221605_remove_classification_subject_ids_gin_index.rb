class RemoveClassificationSubjectIdsGinIndex < ActiveRecord::Migration
  def up
    if index_exists?(:classifications, :subject_ids)
      remove_index :classifications, column: :subject_ids
    end
  end

  def down
    add_index :classifications, :subject_ids, using: :gin
  end
end
