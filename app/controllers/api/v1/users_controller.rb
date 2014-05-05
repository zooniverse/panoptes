module Api
  module V1
    class UsersController < Api::ApiController
      doorkeeper_for :all

      def show
        render json: current_resource_owner.to_json, content_type: api_content
      end
    end
  end
end
