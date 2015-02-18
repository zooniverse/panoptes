module JsonApiController
  module PreconditionCheck
    def precondition_check
      if !precondition
        raise PreconditionNotPresent, precondition_error_msg
      elsif precondition_fails?
        raise PreconditionFailed
      end
    end
    
    def precondition
      case action_name
      when "update", "destroy"
        request.headers["If-Match"]
      end
    end

    def precondition_fails?
      query = resource_class.where(id: resource_ids)
      etag = combine_etags(query)
      key = ActiveSupport::Cache.expand_cache_key(etag)
      etag = %("#{Digest::MD5.hexdigest(key)}")
      !(etag == precondition)
    end

    def precondition_error_msg
      "Request requires #{precondition} header to be present"
    end
  end
end
