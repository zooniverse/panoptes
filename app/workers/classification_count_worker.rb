class ClassificationCountWorker
  include Sidekiq::Worker

  def perform(subject_id, workflow_id)
    if Workflow.find(workflow_id).project.live
      count = SubjectWorkflowCount.find_or_create_by!(subject_id: subject_id, workflow_id: workflow_id)
      SubjectWorkflowCount.increment_counter(:classifications_count, count.id)
      Project.increment_counter :classifications_count, workflow.project.id
      Workflow.increment_counter :classifications_count, workflow.id
      RetirementWorker.perform_async(count.id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
