class RemoveDupIndexesUseCompounds < ActiveRecord::Migration
  def change
    if index_exists?(:classification_subjects, :classification_id)
      remove_index :classification_subjects, column: :classification_id
    end

    if index_exists?(:memberships, :user_group_id)
      remove_index :memberships, column: :user_group_id
    end

    if index_exists?(:set_member_subjects, :subject_id)
      remove_index :set_member_subjects, column: :subject_id
    end

    if index_exists?(:subject_sets_workflows, :workflow_id)
      remove_index :subject_sets_workflows, column: :workflow_id
    end

    if index_exists?(:subject_workflow_counts, :subject_id)
      remove_index :subject_workflow_counts, column: :subject_id
    end

    if index_exists?(:workflow_tutorials, :workflow_id)
      remove_index :workflow_tutorials, column: :workflow_id
    end
  end
end
