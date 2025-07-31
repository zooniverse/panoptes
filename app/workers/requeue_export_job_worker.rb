# frozen_string_literal: true

require 'sidekiq/api'

class RequeueExportJobWorker
  include Sidekiq::Worker

  sidekiq_options queue: :dumpworker

  EXPORT_MEDIA_TYPES = %w[
    project_aggregations_export
    project_classifications_export
    project_subjects_export
    project_workflow_contents_export
    project_workflows_export
    workflow_classifications_export
  ].freeze

  WORKER_MAPPING = {
    'project_classifications_export' => ::ClassificationsDumpWorker,
    'workflow_classifications_export' => ::ClassificationsDumpWorker,
    'project_subjects_export' => ::SubjectsDumpWorker,
    'project_workflow_contents_export' => ::WorkflowsDumpWorker,
    'project_workflows_export' => ::WorkflowsDumpWorker,
  }.freeze

  STATE_COMPLETED = 'ready'
  STATE_FAILED = 'failed'
  STATE_REQUEUED = 'requeued'

  def perform
    fetch_uncompleted_exports.find_each { |media| process_media_status(media) }
  end

  private

  def fetch_uncompleted_exports
    Medium.where(type: EXPORT_MEDIA_TYPES)
          .where("metadata ->> 'state' = 'creating'")
  end

  def process_media_status(media)
    metadata = media.metadata.is_a?(Hash) ? media.metadata : {}

    target_job_id = metadata['job_id']

    return if target_job_id.blank?
    return if find_job_in_set?(Sidekiq::ScheduledSet.new, target_job_id)
    return if find_job_in_set?(Sidekiq::RetrySet.new, target_job_id)

    if find_job_in_set?(Sidekiq::DeadSet.new, target_job_id)
      update_media_metadata(media, STATE_FAILED)
      return
    end

    return if any_queue_contains?(target_job_id)

    requeue_from_media(media)
  rescue StandardError => e
    Rails.logger.error "Error processing media ID #{media.id} (job_id: #{target_job_id || 'N/A'}): #{e.message}"
  end

  def update_media_metadata(media, values={})
    media.with_lock do
      media.metadata ||= {}
      values.each do |k, v|
        media.metadata[k.to_s] = v
      end
      media.save!
    end
  end

  def any_queue_contains?(job_id)
    Sidekiq::Queue.all.any? do |queue|
      queue.any? { |j| j.jid == job_id }
    end
  end

  def find_job_in_set?(set, job_id)
    job_object = set.find_job(job_id)
    return false unless job_object

    job_object
  end

  def get_media_owner(media)
    case media.linked_type
    when 'Project'
      Project.find(media.linked_id).owner
    when 'Subject'
      Subject.find(media.linked_id).project.owner
    when 'Workflow'
      Workflow.find(media.linked_id).owner
    end
  end

  def requeue_from_media(media)
    worker = WORKER_MAPPING[media.type]
    if worker
      id = media.path_opts[1]
      owner = get_media_owner(media)
      worker.perform_async(id, media.linked_type.downcase, media.id, owner.id)
    else
      Rails.logger.error "No worker for #{media.id}"
    end
  end
end
