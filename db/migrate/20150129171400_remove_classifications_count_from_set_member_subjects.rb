class RemoveClassificationsCountFromSetMemberSubjects < ActiveRecord::Migration
  def change
    remove_column :set_member_subjects, :classifications_count, :integer, default: 0, null: false
  end
end
