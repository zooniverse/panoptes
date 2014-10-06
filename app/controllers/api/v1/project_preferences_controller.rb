class Api::V1::ProjectPreferencesController < Api::ApiController
  include JsonApiController

  before_filter :require_login
  doorkeeper_for :all, scopes: [:project]
  resource_actions :index, :show, :create, :update

  allowed_params :create, :email_communication, preferences: [:tutorial],
    links: [:project]

  allowed_params :update, :email_communication, preferences: [:tutorial]

  private

  def serializer
    UserProjectPreferenceSerializer
  end
  
  def resource_name
    "project_preference"
  end

  def resource_class
    UserProjectPreference
  end

  def build_resource_for_create(create_params)
    create_params[:links][:user] = api_user.user
    super(create_params)
  end

  def visible_scope
    UserProjectPreference.visible_to(api_user)
  end

  def new_items(relation, value)
    super(relation, value, :preferences)
  end
end
