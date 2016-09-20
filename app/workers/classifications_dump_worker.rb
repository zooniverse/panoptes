require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    CSV.open(csv_file_path, 'wb') do |csv|
      formatter = Formatter::Csv::Classification.new(project, cache)
      csv << formatter.class.headers
      completed_project_classifications.find_in_batches do |batch|
        subject_ids = setup_subjects_cache(batch)
        setup_retirement_cache(batch, subject_ids)
        batch.each do |classification|
          csv << formatter.to_array(classification)
        end
      end
    end
  end

  def completed_project_classifications
    project
      .classifications
      .complete
      .joins(:workflow)
      .includes(:user, workflow: [:workflow_contents])
  end

  private

  def cache
    @cache ||= ClassificationDumpCache.new
  end

  def setup_subjects_cache(classifications)
    classification_ids = classifications.map(&:id).join(",")
    sql = "SELECT classification_id, subject_id FROM classification_subjects where classification_id IN (#{classification_ids})"
    c_s_ids = ActiveRecord::Base.connection.select_rows(sql)
    cache.reset_classification_subjects(c_s_ids)
    subject_ids = c_s_ids.map { |cs| cs.last }
    cache.reset_subjects(Subject.unscoped.where(id: subject_ids).load)
    subject_ids
  end

  def setup_retirement_cache(classifications, subject_ids)
    workflow_ids = classifications.map(&:workflow_id).uniq
    retired_counts = SubjectWorkflowStatus.retired.where(
      subject_id: subject_ids,
      workflow_id: workflow_ids
    ).load
    cache.reset_subject_workflow_statuses(retired_counts)
  end
end
