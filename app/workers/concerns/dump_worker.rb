module DumpWorker
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks
    define_callbacks :dump
    attr_reader :resource, :medium, :scope, :processor
  end

  def perform(resource_id, resource_type, medium_id=nil, requester_id=nil, *args)
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:dump_worker_exports].enabled?
    @resource_type = resource_type
    @resource_id = resource_id

    if @resource = CsvDumps::FindsDumpResource.find(resource_type, resource_id)
      @medium = CsvDumps::FindsMedium.new(medium_id, dump_type, resource_file_path, @resource, content_disposition).medium
      scope = get_scope(resource)
      @processor = CsvDumps::GenericDumpProcess.new(formatter, scope, medium)

      run_callbacks :dump do
        @processor.execute
      end
    end
  end

  def dump_target
    @dump_target ||= self.class.to_s.underscore.match(/\A(\w+)_dump_worker\z/)[1]
  end

  def dump_type
    "#{@resource_type}_#{dump_target}_export"
  end

  def resource_file_path
    [dump_type, @resource_id.to_s]
  end

  def content_disposition
    case @resource_type
    when "workflow"
      name = @resource.display_name.parameterize
    when "project"
      name = @resource.slug.split("/")[1]
    end
    "attachment; filename=\"#{name}-#{dump_target}.csv\""
  end

  def read_from_database(&block)
    DatabaseReplica.read("dump_data_from_read_slave", &block)
  end
end
