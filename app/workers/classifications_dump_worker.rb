require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    CSV.open(csv_file_path, 'wb') do |csv|
      cache = ClassificationDumpCache.new
      formatter = Formatter::Csv::Classification.new(project, cache)

      csv <<  formatter.class.headers

      completed_project_classifications.find_in_batches do |group|
        subject_ids = group.flat_map(&:subject_ids).uniq
        workflow_ids = group.map(&:workflow_id).uniq

        cache.reset_subjects(Subject.where(id: subject_ids).load)
        retired_counts = SubjectWorkflowCount.retired.where(
          subject_id: subject_ids,
          workflow_id: workflow_ids
        ).load
        cache.reset_subject_workflow_counts(retired_counts)

        group.each { |classification| csv << formatter.to_array(classification) }
      end
    end
  end

  def completed_project_classifications
    project.classifications
    .complete
    .joins(:workflow)
    .includes(:user, workflow: [:workflow_contents])
  end
end
