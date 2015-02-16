class AddClassificationCountToSetMemberSubjects < ActiveRecord::Migration
  def change
    add_column :set_member_subjects, :classification_count, :integer, default: 0
  end
end
