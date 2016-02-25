class PublishRetirementEventWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    counters = {
      project_id: workflow.project_id,
      workflow_id: workflow.id,
      subjects_count: workflow.subjects_count,
      retired_subjects_count: workflow.retired_subjects_count,
      classifications_count: workflow.classifications_count
    }

    ZooStream.publish(event: 'workflow_counters',
                      data: counters,
                      shard_by: workflow.id)
  rescue ActiveRecord::RecordNotFound
  end
end
