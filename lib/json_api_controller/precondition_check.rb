module JsonApiController
  module PreconditionCheck
    HEADER_NAME = "If-Match".freeze

    def precondition_check
      if !precondition
        raise PreconditionNotPresent, precondition_error_msg
      elsif precondition_fails?
        raise PreconditionFailed
      end
    end

    private

    def precondition
      case action_name
      when "update", "destroy"
        request.headers[HEADER_NAME]
      end
    end

    def precondition_fails?
      query = resource_class.where(id: resource_ids)
      current_etag = gen_etag(query)
      current_etag = "W/#{current_etag}" if weak_etag?(precondition)
      !(current_etag == precondition)
    end

    def precondition_error_msg
      "Request requires #{HEADER_NAME} header to be present"
    end

    def weak_etag?(etag)
      !!etag.match(/^\AW\//)
    end
  end
end
