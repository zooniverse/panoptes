class AddRetiredSetMemberSubjectCountToSubjectSets < ActiveRecord::Migration
  def change
    add_column :subject_sets, :retired_set_member_subjects_count, :integer, default: 0, null: false
  end
end
