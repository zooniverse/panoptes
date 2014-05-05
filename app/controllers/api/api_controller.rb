module Api
  class ApiController < ApplicationController

    def api_content
      "application/vnd.zooniverse.v1+json"
    end

    def current_resource_owner
      @current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

  end
end
