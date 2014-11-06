class AddPriorityToSetMemberSubjects < ActiveRecord::Migration
  def change
    add_column :set_member_subjects, :priority, :decimal
  end
end
