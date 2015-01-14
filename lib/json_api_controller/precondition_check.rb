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
        request.headers["If-Unmodified-Since"]
      end
    end

    def precondition_fails?
      !resource_class.where("updated_at <= ?", precondition).exists?(params[:id])
    end

    def precondition_error_msg
      "Request requires #{precondition} header to be present"
    end
  end
end
