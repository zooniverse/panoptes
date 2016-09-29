module Api

  class EventsController < ApplicationController

    KNOWN_EVENTS = %w( activity workflow_activity )

    def self.resource_name
      "event"
    end

    @actions = [:create]

    include JsonApiController::JsonSchemaValidator

    before_action :require_basic_authentication

    def create
      respond_to do |format|
        format.json do
          response_status = :unprocessable_entity
          if event_params_check
            response_status = process_incoming_event
          end
          render status: response_status, nothing: true
        end
      end
    end

    private

    def require_basic_authentication
      authenticate_or_request_with_http_basic do |username, password|
        Panoptes::EventsApi.username == username &&
          Panoptes::EventsApi.password == password
      end
    end

    def process_incoming_event
      if upp = user_project_preference
        upp.legacy_count[create_params[:workflow]] = create_params[:count]

        if upp.save
          :ok
        else
          :unprocessable_entity
        end
      end
    end

    def event_params_check
      required_params && known_event? && legacy_zoo_project_exists?
    end

    def required_params
      params_to_check = [ create_params[:project_id], create_params[:zooniverse_user_id] ]
      params_to_check.all? { |param| !param.blank? }
    rescue JsonSchema::ValidationError,
      ActionController::ParameterMissing,
      ActionDispatch::ParamsParser::ParseError
      return false
    end

    def known_event?
      unless known_event = create_params[:kind] && KNOWN_EVENTS.include?(create_params[:kind])
        notify_honeybadger_of_unknown_event
      end
      known_event
    end

    def notify_honeybadger_of_unknown_event
      Honeybadger.notify(
        error_class:   "Legacy API Event",
        error_message: "Unknown Legacy API Event Message Received",
        parameters:    params
      )
    end

    def user_project_preference
      user_zoo_id = create_params[:zooniverse_user_id]
      project = legacy_zoo_project
      user = User.find_by(zooniverse_id: user_zoo_id) if user_zoo_id

      if user
        UserProjectPreferences::FindOrCreateUponClassification.run! project: project, user: user
      end
    end

    def resource_sym
      self.class.resource_name.to_sym
    end

    def legacy_zoo_project
      @legacy_zoo_project ||=
        Project.where(migrated: true)
        .where("configuration ->> 'zoo_home_project_id' = ?", create_params[:project_id].to_s)
        .first
    end

    def legacy_zoo_project_exists?
      !!legacy_zoo_project
    end
  end
end
