class ClassificationCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform(subject_id, workflow_id)
    workflow = Workflow.find(workflow_id)

    if workflow.project.live
      count = SubjectWorkflowStatus.find_or_create_by!(subject_id: subject_id, workflow_id: workflow_id)

      counter = SubjectWorkflowCounter.new(count)
      count.update_column(:classifications_count, counter.classifications)

      ProjectClassificationsCountWorker.perform_async(workflow.project.id)
      RetirementWorker.perform_async(count.id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
