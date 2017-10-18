require 'csv'

class SubjectsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:dump_worker_exports].enabled?
    CSV.open(csv_file_path, 'wb') do |csv|
      headers = Formatter::Csv::Subject.headers
      csv << headers

      read_from_database do
        project_subjects.find_each do |subject|
          Formatter::Csv::Subject.new(resource, subject).to_rows.each do |hash|
            csv << hash.values_at(*headers)
          end
        end
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
