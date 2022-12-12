class AddGinIndexToClassificationsSubjectIds < ActiveRecord::Migration
  def change
    add_index :classifications, :subject_ids, using: :gin
  end
end
