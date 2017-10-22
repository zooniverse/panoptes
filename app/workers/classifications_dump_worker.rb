require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    CSV.open(csv_file_path, 'wb') do |csv|
      strategy = if Panoptes.flipper.enabled?("dump_classifications_csv_using_export_rows")
                   # TODO: feature flag and backfill the exports rows while creating?
                   ExportRowDumper.new(self)
                 else
                   FormattingDumper.new(self)
                 end
      strategy.export(csv)
    end
  end

  class Dumper
    attr_reader :context
    delegate :read_from_database, :resource, :resource_type, to: :context

    def self.headers
      @headers ||= Formatter::Csv::Classification.headers
    end

    def initialize(context)
      @context = context
    end

    def export(csv)
      fail NotImplementedError
    end
  end

  class ExportRowDumper < Dumper
    def export(csv)
      csv << self.class.headers

      read_from_database do
        classification_export_rows_scope.find_each do |export_row|
          formatted_cols = self.class.headers.map do |header|
            # TODO: handle subject retirement metadata update
            export_row.send(header)
          end
          csv << formatted_cols
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
  end

  class FormattingDumper < Dumper

    def export(csv)
      formatter = Formatter::Csv::Classification.new(cache)
      csv << formatter.class.headers

      read_from_database do
        completed_resource_classifications.find_in_batches do |batch|
          subject_ids = setup_subjects_cache(batch)
          setup_retirement_cache(batch, subject_ids)
          batch.each do |classification|
            csv << formatter.to_array(classification)
          end
        end
      end
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
end
