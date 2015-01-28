class Api::V1::ProjectPreferencesController < Api::ApiController
  include PreferencesController

  doorkeeper_for :all, scopes: [:project]
  schema_type :strong_params

  allowed_params :create, :email_communication, preferences: [:tutorial],
    links: [:project]

  allowed_params :update, :email_communication, preferences: [:tutorial]

  private

  def resource_name
    "project_preference"
  end
end
