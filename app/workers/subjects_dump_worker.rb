require 'csv'

class SubjectsDumpWorker
  include Sidekiq::Worker
  include RateLimitDumpWorker

  sidekiq_options queue: ENV.fetch('DUMP_WORKER_SIDEKIQ_QUEUE', 'data_high').to_sym

  attr_reader :resource, :medium, :scope, :processor

  def perform(resource_id, resource_type, medium_id=nil, requester_id=nil, *args)
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:dump_worker_exports].enabled?

    if @resource = CsvDumps::FindsDumpResource.find(resource_type, resource_id)
      @medium = CsvDumps::FindsMedium.new(medium_id, @resource, dump_target).medium
      scope = get_scope(resource)
      @processor = CsvDumps::DumpProcessor.new(formatter, scope, medium)
      @processor.execute
      DumpMailer.new(resource, medium, dump_target).send_email
    end
  end

  def formatter
    @formatter ||= Formatter::Csv::Subject.new(resource)
  end

  def get_scope(resource)
    CsvDumps::SubjectScope.new(resource)
  end

  def dump_target
    "subjects"
  end
end
