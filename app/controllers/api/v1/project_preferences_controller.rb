class Api::V1::ProjectPreferencesController < Api::ApiController
  include PreferencesController

  doorkeeper_for :all, scopes: [:project]
  schema_type :json_schema

  private

  def resource_name
    "project_preference"
  end
end
