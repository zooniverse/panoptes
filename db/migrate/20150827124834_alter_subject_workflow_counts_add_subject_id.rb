class AlterSubjectWorkflowCountsAddSubjectId < ActiveRecord::Migration
  def up
    add_column :subject_workflow_counts, :subject_id, :integer, index: true
    add_foreign_key :subject_workflow_counts, :subjects, on_delete: :restrict

    # Create new aggregated (per subject) SWC records
    execute <<-END
      INSERT INTO subject_workflow_counts (subject_id, workflow_id, classifications_count, created_at, updated_at, retired_at)
      SELECT sms.subject_id,
             workflow_id,
             MAX(classifications_count) AS classifications_count,
             MIN(swc.created_at) AS created_at,
             MAX(swc.updated_at) AS updated_at,
             MIN(swc.retired_at) AS retired_at
      FROM subject_workflow_counts swc
      INNER JOIN set_member_subjects sms ON swc.set_member_subject_id = sms.id
      GROUP BY sms.subject_id, workflow_id
      ORDER BY classifications_count DESC
    END

    # Remove old SWCs
    execute <<-END
      DELETE FROM subject_workflow_counts WHERE subject_id IS NULL AND set_member_subject_id IS NOT NULL;
    END

    add_index :subject_workflow_counts, [:subject_id, :workflow_id], unique: true
    change_column_null :subject_workflow_counts, :subject_id, false
  end

  def down
    remove_column :subject_workflow_counts, :subject_id
  end
end
