class Api::V1::ProjectPreferencesController < Api::ApiController
  include PreferencesController

  require_authentication :all, scopes: [:project]
  extra_schema_actions :update_settings
  schema_type :json_schema
  before_action :validate_records, only: [:update_settings]

  def update_settings
    upp = UserProjectPreference.find_or_initialize_by(project_id: params_for[:project_id],
                                                      user_id: params_for[:user_id])
    upp.settings.merge! params_for[:settings]
    upp.save
    render status: :ok, nothing: true
  end

  private

  def find_project
    Project.find params_for[:project_id] || nil
  end

  def find_user
    User.find params_for[:user_id] || nil
  end

  def validate_records
    raise UserProjectPreference::RecordNotFound.new("User not found") unless find_user
    raise UserProjectPreference::RecordNotFound.new("Project not found") unless find_project
    raise UserProjectPreference::Unauthorized.new unless project.owner?(api_user.user)
  end

  def resource_name
    "project_preference"
  end
end
