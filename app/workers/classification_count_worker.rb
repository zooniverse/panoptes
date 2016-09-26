class ClassificationCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform(subject_id, workflow_id, was_update=false)
    workflow = Workflow.find(workflow_id)

    if workflow.project.live
      count = nil

      Workflow.transaction do
        count = SubjectWorkflowStatus.find_or_create_by!(subject_id: subject_id, workflow_id: workflow_id)
        count.class.increment_counter(:classifications_count, count.id) unless was_update
      end

      ProjectClassificationsCountWorker.perform_async(workflow.project.id)
      SubjectWorkflowStatusCountWorker.perform_async(count.id)
      RetirementWorker.perform_async(count.id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
