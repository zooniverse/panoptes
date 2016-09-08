class ClassificationCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform(subject_id, workflow_id, was_update=false)
    workflow = Workflow.find(workflow_id)

    Workflow.transaction do
      if workflow.project.live
        count = SubjectWorkflowStatus.find_or_create_by!(subject_id: subject_id, workflow_id: workflow_id)
        count.class.increment_counter(:classifications_count, count.id) unless was_update
      end
    end

    SubjectWorkflowStatusCountWorker.perform_async(count.id)
    ProjectClassificationsCountWorker.perform_async(workflow.project.id)
    RetirementWorker.perform_async(count.id)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
