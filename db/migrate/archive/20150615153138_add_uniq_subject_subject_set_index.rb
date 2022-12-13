class AddUniqSubjectSubjectSetIndex < ActiveRecord::Migration
  def change
    add_index :set_member_subjects, [:subject_id, :subject_set_id], unique: true
  end
end
