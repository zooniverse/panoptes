class UssSubjectIdsDefaultValueIsEmptyArray < ActiveRecord::Migration
  def up
    change_column :user_seen_subjects, :subject_ids, :integer, array: true, default: [], null: false
  end

  def down
    change_column :user_seen_subjects, :subject_ids, :integer, array: true, default: nil, null: true
  end
end
