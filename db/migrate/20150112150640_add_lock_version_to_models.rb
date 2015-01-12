class AddLockVersionToModels < ActiveRecord::Migration
  def change
    %i(projects workflows collections subject_sets subjects set_member_subjects user_groups user_subject_queues).each do |table|
      add_column table, :lock_version, :integer, default: 0
    end
  end
end
