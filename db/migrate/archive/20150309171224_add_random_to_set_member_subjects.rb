class AddRandomToSetMemberSubjects < ActiveRecord::Migration
  def change
    add_column :set_member_subjects, :random, :decimal
    SetMemberSubject.find_each{ |sms| sms.update!(random: rand) }
    change_column :set_member_subjects, :random, :decimal, null: false
    add_index :set_member_subjects, :random
  end
end
