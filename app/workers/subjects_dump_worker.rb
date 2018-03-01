require 'csv'

class SubjectsDumpWorker
  include Sidekiq::Worker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  include ActiveSupport::Callbacks
  define_callbacks :dump
  attr_reader :resource, :medium, :scope, :processor

  def perform(resource_id, resource_type, medium_id=nil, requester_id=nil, *args)
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:dump_worker_exports].enabled?

    if @resource = CsvDumps::FindsDumpResource.find(resource_type, resource_id)
      @medium = CsvDumps::FindsMedium.new(medium_id, @resource, dump_target).medium
      scope = get_scope(resource)
      @processor = CsvDumps::DumpProcessor.new(formatter, scope, medium)

      run_callbacks :dump do
        @processor.execute
      end
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
