class AddSubjectsCounterCacheToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :real_set_member_subjects_count, :integer, default: 0, null: false
  end
end
