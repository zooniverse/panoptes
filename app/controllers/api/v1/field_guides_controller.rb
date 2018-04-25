class Api::V1::FieldGuidesController < Api::ApiController
  include RoleControl::RoledController
  include SyncResourceTranslationStrings

  require_authentication :update, :create, :destroy, scopes: [:project]

  resource_actions :default

  schema_type :json_schema

  before_filter :set_language_if_missing, only: [:index]

  private

  def set_language_if_missing
    params[:language] ||= "en"
  end
end
