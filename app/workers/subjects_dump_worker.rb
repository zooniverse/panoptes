require 'csv'

class SubjectsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    csv_formatter = Formatter::Csv::Subject.new(project)
    CSV.open(csv_file_path, 'wb') do |csv|
      csv << csv_formatter.class.headers
      project_subjects.find_each do |subject|
        csv << csv_formatter.to_array(subject)
      end
    end
  end

  def project_subjects
    SetMemberSubject.joins(:subject_set).merge(project.subject_sets)
  end
end
