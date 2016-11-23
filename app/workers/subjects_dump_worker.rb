require 'csv'

class SubjectsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    csv_formatter = Formatter::Csv::Subject.new(resource)
    CSV.open(csv_file_path, 'wb') do |csv|
      csv << csv_formatter.class.headers
      project_subjects.find_each do |subject|
        csv << csv_formatter.to_array(subject)
      end
    end
  end

  def project_subjects
    Subject
      .joins(:subject_sets)
      .eager_load(:subject_sets, :locations)
      .merge(resource.subject_sets)
  end
end
