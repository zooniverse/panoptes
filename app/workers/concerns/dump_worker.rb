module DumpWorker
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks
    include DumpCommons
    define_callbacks :dump
    attr_reader :resource, :scope
  end

  def perform(resource_id, resource_type, medium_id=nil, requester_id=nil, *args)
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:dump_worker_exports].enabled?
    @resource_type = resource_type
    @resource_id = resource_id

    if @resource = CsvDumps::FindsDumpScope.find(resource_type, resource_id)
      @medium_id = medium_id
      @scope = self

      begin
        run_callbacks :dump do
          perform_dump(*args)
          upload_dump { set_ready_state }
        end
      ensure
        cleanup_dump
      end
    end
  end

  def perform_dump
    csv_dump << formatter.class.headers if formatter.class.headers

    read_from_database do
      scope.each do |model|
        csv_dump << formatter.to_array(model)
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

  def medium
    @medium ||= CsvDumps::FindsMedium.new(@medium_id, dump_type, resource_file_path, @resource, content_disposition).medium
  end

  def set_ready_state
    medium.metadata["state"] = 'ready'
    medium.save!
  end

  def write_to_s3(gzip_file_path)
    medium.put_file(gzip_file_path, compressed: true)
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
