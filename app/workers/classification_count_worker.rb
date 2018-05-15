class ClassificationCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform(subject_id, workflow_id)
    workflow = Workflow.find(workflow_id)

    if workflow.project.live && Panoptes.flipper["classification_counters"].enabled?
      count = nil

      Workflow.transaction do
        count = SubjectWorkflowStatus.find_or_create_by!(subject_id: subject_id, workflow_id: workflow_id)
        count.class.increment_counter(:classifications_count, count.id)
      end

      SubjectWorkflowStatusCountWorker.perform_async(count.id)
      WorkflowClassificationsCountWorker.perform_in(5.seconds, workflow.id)
      RetirementWorker.perform_async(count.id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
