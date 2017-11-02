require 'csv'

class SubjectsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:dump_worker_exports].enabled?

    headers = Formatter::Csv::Subject.headers
    csv_dump << headers

    each do |model|
      Formatter::Csv::Subject.new(resource, model).to_rows.each do |hash|
        csv_dump << hash.values_at(*headers)
      end
    end

  end

  def formatter
    @formatter ||= Formatter::Csv::Subject
  end

  def each
    read_from_database do
      project_subjects.find_each do |subject|
        yield subject
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
