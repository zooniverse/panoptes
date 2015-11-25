class Api::V1::CollectionPreferencesController < Api::ApiController
  include PreferencesController

  require_authentication :all, scopes: [:collection]
  schema_type :strong_params

  allowed_params :create, preferences: [:display], links: [:collection]

  allowed_params :update, preferences: [:display]

  private

  def resource_name
    "collection_preference"
  end
end
