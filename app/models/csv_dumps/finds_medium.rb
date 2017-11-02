module CsvDumps
  class FindsMedium
    def initialize(id, dump_type, resource_file_path, resource, content_disposition)
      @medium_id = id
      @dump_type = dump_type
      @resource_file_path = resource_file_path
      @resource = resource
      @content_disposition = content_disposition
    end

    def medium
      @medium ||= @medium_id ? load_medium : create_medium
    end

    def create_medium
      Medium.create!(
        content_type: "text/csv",
        type: @dump_type,
        path_opts: @resource_file_path,
        linked: @resource,
        metadata: { state: 'creating' },
        private: true,
        content_disposition: @content_disposition
      )
    end

    def load_medium
      m = Medium.find(@medium_id)
      metadata = m.metadata.merge("state" => "creating")
      m.update!(
        path_opts: @resource_file_path,
        private: true,
        content_type: "text/csv",
        content_disposition: @content_disposition,
        metadata: metadata
      )
      m
    end
  end
end
