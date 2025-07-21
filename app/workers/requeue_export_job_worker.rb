# frozen_string_literal: true

require 'sidekiq-status'
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
  ]

  STATE_COMPLETED = 'completed'
  STATE_FAILED    = 'failed'
  STATE_REQUEUED  = 'requeued'

  def perform
    Rails.logger.info 'Starting RequeueExportJobWorker to check export statuses.'

    export_media = Medium.where(type: EXPORT_MEDIA_TYPES).where("metadata ->> 'state' IN (?)", %w[creating requeued failed interrupted])

    if export_media.empty?
      Rails.logger.info 'No uncompleted export media found to process.'
      return
    end

    Rails.logger.info "Found #{export_media.count} uncompleted export media to check."
    export_media.find_each do |media|
      process_media_status(media)
    end

    Rails.logger.info 'Finished RequeueExportJobWorker.'
  end

  private
  
  def process_media_status(media)
    Rails.logger.info "Processing Media ID: #{media.id}, Type: #{media.type}, Current State: #{media.metadata&.[]('state')}"

    metadata = media.metadata.is_a?(Hash) ? media.metadata : {}

    if metadata['job_id'].blank?
      Rails.logger.warn "Media ID #{media.id} has no 'job_id' in its metadata. Marking as '#{STATE_FAILED}'."
      update_media_metadata(media, state: STATE_FAILED)
      return
    end

    target_job_id = metadata['job_id']
    Rails.logger.info "Checking status for job_id: #{target_job_id} linked to Media ID: #{media.id}"

    job_status = Sidekiq::Status.status(target_job_id)
    Rails.logger.info "Sidekiq::Status for #{target_job_id}: #{job_status}"

    case job_status
    when :complete
      Rails.logger.info "Job #{target_job_id} is complete. Marking media ID #{media.id} as '#{STATE_COMPLETED}'."
      update_media_metadata(media, state: STATE_COMPLETED)
    when :failed, :interrupted, :retrying
      Rails.logger.warn 'Job failed or was interrupted. Attempting to requeue.'
      if requeue_sidekiq_job(target_job_id)
        Rails.logger.info "Job #{target_job_id} successfully requeued. Updating state to '#{STATE_REQUEUED}'."
        update_media_metadata(media, state: STATE_REQUEUED)
      else
        Rails.logger.error "Failed to requeue job #{target_job_id}. Marking as '#{STATE_FAILED}'."
        update_media_metadata(media, state: STATE_FAILED, job_id: nil)
      end
    when :queued, :working, :scheduled
      Rails.logger.info "Job #{target_job_id} is still active (#{job_status})."
    when nil
      Rails.logger.warn "Sidekiq::Status returned nil for job #{target_job_id}. Attempting to find via Sidekiq::API."

      found_via_api = find_and_requeue_via_sidekiq_api(target_job_id, media)

      unless found_via_api
        Rails.logger.warn "Job #{target_job_id} not found in any Sidekiq sets. Assuming complete and marking '#{STATE_COMPLETED}'."
        update_media_metadata(media, state: STATE_COMPLETED)
      end
    else
      Rails.logger.warn "Unknown Sidekiq::Status for job #{target_job_id}: #{job_status}. Skipping."
    end
  rescue StandardError => e
    Rails.logger.error "Error processing media ID #{media.id} (job_id: #{target_job_id || 'N/A'}): #{e.message}"
    update_media_metadata(media, state: STATE_FAILED, job_id: nil)
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

  # Checks all Sidekiq sets (queues, retry, scheduled, dead) for a job.
  # If found in retry/dead, it attempts to requeue it.
  # Returns true if the job is found in any active Sidekiq state, false otherwise.
  def find_and_requeue_via_sidekiq_api(job_id, media)
    Sidekiq::Queue.all.each do |queue|
      job = queue.find { |j| j.jid == job_id }
      if job
        Rails.logger.info "Job #{job_id} found in queue '#{queue.name}'. Active. Media ID: #{media.id}"
        return true
      end
    end

    retry_set = Sidekiq::RetrySet.new
    retry_job_object = retry_set.find_job(job_id)
    if retry_job_object
      Rails.logger.info "Job #{job_id} found in RetrySet. Requeuing."
      perform_requeue_action(retry_job_object, job_id, 'RetrySet')
      return true
    end

    dead_set = Sidekiq::DeadSet.new
    dead_job_object = dead_set.find_job(job_id)
    if dead_job_object
      Rails.logger.info "Job #{job_id} found in DeadSet. Requeuing."
      perform_requeue_action(dead_job_object, job_id, 'DeadSet')
      return true
    end

    false
  end

  def requeue_sidekiq_job(job_id)
    Rails.logger.debug "Attempting to requeue job: #{job_id} from direct call."

    retry_set = Sidekiq::RetrySet.new
    job_in_retry = retry_set.find_job(job_id)

    if job_in_retry
      perform_requeue_action(job_in_retry, job_id, 'RetrySet')
      return true
    end

    dead_set = Sidekiq::DeadSet.new
    job_in_dead_set_object = dead_set.find_job(job_id)

    if job_in_dead_set_object
      perform_requeue_action(job_in_dead_set_object, job_id, 'DeadSet')
      return true
    end

    false
  end

  def perform_requeue_action(job_object, job_id, source_set_name)
    if job_object.respond_to?(:requeue)
      Rails.logger.debug "Using 'requeue' method for job #{job_id} from #{source_set_name}."
      job_object.requeue
    elsif job_object.respond_to?(:add_to_queue)
      Rails.logger.warn "Using 'add_to_queue' method for job #{job_id} from #{source_set_name}."
      job_object.add_to_queue
    else
      Rails.logger.error "Job object for #{job_id} from #{source_set_name} has neither 'requeue' nor 'add_to_queue'. Cannot re-enqueue."
      return false
    end
    true
  end
end
