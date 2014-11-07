class SetMemberSubjectActiveByDefault < ActiveRecord::Migration
  def change
    change_column :set_member_subjects, :state, :integer, default: 0, null: false 
  end
end
