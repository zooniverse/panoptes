module CsvDumps
  class FindsMedium
    attr_reader :medium_id, :resource, :dump_target

    def initialize(id, resource, dump_target)
      @medium_id = id
      @resource = resource
      @dump_target = dump_target
    end

    def medium
      @medium ||= medium_id ? load_medium : create_medium
    end

    def create_medium
      Medium.create!(
        content_type: "text/csv",
        type: dump_type,
        path_opts: resource_file_path,
        linked: resource,
        metadata: { state: 'creating' },
        private: true,
        content_disposition: content_disposition
      )
    end

    def load_medium
      m = Medium.find(medium_id)
      metadata = m.metadata.merge("state" => "creating")
      m.update!(
        path_opts: resource_file_path,
        private: true,
        content_type: "text/csv",
        content_disposition: content_disposition,
        metadata: metadata
      )
      m
    end

    def dump_type
      "#{resource_type}_#{dump_target}_export"
    end

    def resource_file_path
      [dump_type, resource.id.to_s]
    end

    def content_disposition
      case resource
      when Workflow, SubjectSet
        name = resource.display_name.parameterize
      when Project
        name = resource.slug.split("/")[1]
      end
      "attachment; filename=\"#{name}-#{dump_target}.csv\""
    end

    def resource_type
      resource.class.name.underscore
    end
  end
end
