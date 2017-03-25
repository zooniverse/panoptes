class RemoveUnusedIndexesSgl2017 < ActiveRecord::Migration
  def change
    # PRE SGL 2017 index cleanup
    remove_index :recents, :classification_id
    remove_index :set_member_subjects, :priority
    remove_index :oauth_applications, [:owner_id, :owner_type]
    remove_index :subject_queues, [:workflow_id, :user_id]
    remove_index :subjects, :activated_state
  end
end
