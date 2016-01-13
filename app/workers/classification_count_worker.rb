class ClassificationCountWorker
  include Sidekiq::Worker

  def perform(subject_id, workflow_id)
    workflow = Workflow.find(workflow_id)

    if workflow.project.live
      count = SubjectWorkflowCount.find_or_create_by!(subject_id: subject_id, workflow_id: workflow_id)
      SubjectWorkflowCount.increment_counter(:classifications_count, count.id)
      # SGL turn these off till we get a better solution
      # Project.increment_counter :classifications_count, workflow.project.id
      # Workflow.increment_counter :classifications_count, workflow.id
      RetirementWorker.perform_async(count.id)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
