class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(count_id)
    count = SubjectWorkflowStatus.find(count_id)
    if count.retire?
      count.retire!

      workflow = count.workflow
      WorkflowRetiredCountWorker.perform_async(workflow.id)
      PublishRetirementEventWorker.perform_async(workflow.id)
      UnfinishWorkflowWorker.perform_async(workflow.id)

      if Panoptes.use_cellect?(workflow)
        RetireCellectWorker.perform_async(count.subject_id, workflow.id)
      end
    end
  end
end
