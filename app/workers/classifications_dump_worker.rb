require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    CSV.open(csv_file_path, 'wb') do |csv|
      formatter = Formatter::Csv::Classification.new(cache)
      csv << formatter.class.headers

    # 1. compute all the missing export models
    # TODO: backfill these models

      read_from_database do
        classification_export_rows_scope.find_in_batches do |batch|
          batch.each do |export_row|
            formatted_cols = Formatter::Csv::Classification.headers.map do |header|
              # TODO: handle subject retirement metadata update
              export_row.send(header)
            end
            csv << formatted_cols
          end
        end
      end
    end
  end

  private

  def classification_export_rows_scope
    scope_filters = case resource_type
    when "workflow"
      { project_id: resource.project_id, workflow_id: resource.id }
    else
      { project_id: resource.id }
    end
    ClassificationExportRow.where(scope_filters)
  end

  def cache
    @cache ||= ClassificationDumpCache.new
  end

  def setup_subjects_cache(classifications)
    classification_ids = classifications.map(&:id).join(",")
    sql = "SELECT classification_id, subject_id FROM classification_subjects where classification_id IN (#{classification_ids})"
    c_s_ids = ActiveRecord::Base.connection.select_rows(sql)
    cache.reset_classification_subjects(c_s_ids)
    subject_ids = c_s_ids.map { |_, subject_id| subject_id }
    cache.reset_subjects(Subject.where(id: subject_ids).load)
    subject_ids
  end

  def completed_resource_classifications
    resource.classifications
    .complete
    .joins(:workflow)
    .includes(:user, workflow: [:workflow_contents])
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
