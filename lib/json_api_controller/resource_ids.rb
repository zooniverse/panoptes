module JsonApiController
  class ResourceIds
    def self.from(params, resource_name)
      non_nil_params = params.to_h.with_indifferent_access.compact
      array_id_params(resource_ids(non_nil_params, resource_name))
    end

    def self.array_id_params(string_id_params)
      ids = string_id_params.split(',')
      if ids.length < 2
        ids.first
      else
        ids
      end
    end

    def self.resource_ids(params, resource_name)
      if resource_name.present? && params.has_key?("#{ resource_name }_id")
        params["#{ resource_name }_id"]
      elsif params.has_key?(:id)
        params[:id]
      else
        ''
      end
    end
  end
end
