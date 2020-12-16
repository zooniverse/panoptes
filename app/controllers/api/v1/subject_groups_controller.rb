# frozen_string_literal: true

module Api
  module V1
    class SubjectGroupsController < Api::ApiController
      include JsonApiController::PunditPolicy

      resource_actions :index, :show
    end
  end
end
