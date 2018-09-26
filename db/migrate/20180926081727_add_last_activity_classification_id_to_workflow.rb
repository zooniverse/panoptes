class AddLastActivityClassificationIdToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :activity_classification_id, :integer

    # backfill the workflow activity columns
    period = CalculateProjectActivityWorker::WorkflowActivityPeriod::ACTIVITY_PERIOD
    Workflow.select(:id).find_each do |workflow|
      # ensure we backfill to the earliest classification id
      # to avoid shrinking the activity counter window
      earliest_period_classification =
        workflow
        .classifications
        .where("created_at >= ?", period)
        .order(:id)
        .first

      if classification_id = earliest_period_classification&.id
        workflow.update_column(:activity_classification_id, classification_id)
      end
    end
  end
end
