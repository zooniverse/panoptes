class AddCounterCacheFieldToSubjectSet < ActiveRecord::Migration
  def change
    add_column :subject_sets, :set_member_subjects_count, :integer, default: 0, null: false
  end
end
