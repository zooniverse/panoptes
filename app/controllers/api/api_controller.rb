module Api
  class ApiController < ApplicationController

    def api_content
      "application/vnd.api+json; version=1"
    end

    def deleted_resource_response
      render status: 204, json: {}, content_type: api_content
    end

    def current_resource_owner
      @current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

  end
end
