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
      run_etag_validation(controlled_resources)
    end

    def precondition_error_msg
      "Request requires #{HEADER_NAME} header to be present"
    end

    def run_etag_validation(query)
      # convert the query scope to an array of active record objects (vs an ActiveRecord::Relation scope)
      # to ensure we generate the cache key based on the underlying Active Record objects
      # and thus have a stable cache key
      #
      # Note: the original SHOW scope query may differ slighly from the UPDATE scope query
      # and thus the resulting query cache key is different and we get a different etag value here
      # vs the provided one.
      #
      # https://api.rubyonrails.org/v5.0/classes/ActiveRecord/Integration.html#method-i-cache_key
      # as opposed to the ActiveRecord::Relation which depends on the query sql
      # https://api.rubyonrails.org/v5.0/classes/ActiveRecord/Relation.html#method-i-cache_key
      current_etag = gen_etag(query.to_a)
      current_etag = "W/#{current_etag}" if weak_etag?(precondition)
      current_etag != precondition
    end

    def weak_etag?(etag)
      !!etag.match(%r{^\AW/})
    end
  end
end
