class Api::V1::CollectionPreferencesController < Api::ApiController
  include JsonApiController

  prepend_before_filter :require_login
  doorkeeper_for :all, scopes: [:collection]
  resource_actions :index, :show, :create, :update
  access_control_for [:update, :update_preferences]

  allowed_params :create, preferences: [:display], links: [:collection]

  allowed_params :update, preferences: [:display]

  def serializer
    UserCollectionPreferenceSerializer
  end
  
  def resource_name
    "collection_preference"
  end

  def resource_class
    UserCollectionPreference
  end

  def build_resource_for_create(create_params)
    create_params[:links][:user] = api_user.user
    super(create_params)
  end

  def visible_scope
    UserCollectionPreference.visible_to(api_user)
  end

  def new_items(relation, value)
    super(relation, value, :preferences)
  end
end
