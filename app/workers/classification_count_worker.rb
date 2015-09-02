class ClassificationCountWorker
  include Sidekiq::Worker

  def perform(subject_id, workflow_id)
    if Workflow.find(workflow_id).project.live
      count = SubjectWorkflowCount.find_or_create_by!(subject_id: subject_id.id, workflow_id: workflow_id)
      SubjectWorkflowCount.increment_counter(:classifications_count, count.id)
      RetirementWorker.perform_async(count.id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
