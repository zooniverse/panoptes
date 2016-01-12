class EmptySubjectQueueWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(workflow_id=nil)
    queue_scope = SubjectQueue.all
     if workflow_id
      workflow = Workflow.find(workflow_id)
      queue_scope = SubjectQueue.where(workflow: workflow)
    end
    queue_scope.update_all(set_member_subject_ids: [])
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
