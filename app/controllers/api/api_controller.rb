module Api
  class ApiController < ApplicationController

    def api_content
      "application/vnd.zooniverse.v1+json"
    end

  end
end
