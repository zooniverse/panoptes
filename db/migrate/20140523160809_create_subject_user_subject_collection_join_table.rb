class CreateSubjectUserSubjectCollectionJoinTable < ActiveRecord::Migration
  def change
    create_join_table :subjects, :user_subject_groups do |t|
      # t.index [:subject_id, :user_subject_group_id]
      # t.index [:user_subject_group_id, :subject_id]
    end
  end
end
