module DumpWorker
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks
    define_callbacks :dump
    attr_reader :resource, :medium, :scope, :processor
  end

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

  def dump_target
    @dump_target ||= self.class.to_s.underscore.match(/\A(\w+)_dump_worker\z/)[1]
  end
end
