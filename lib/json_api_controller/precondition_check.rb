module JsonApiController
  module PreconditionCheck
    HEADER_NAME = "If-Match"

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
      !(gen_etag(query) == precondition)
    end

    def precondition_error_msg
      "Request requires #{HEADER_NAME} header to be present"
    end
  end
end
