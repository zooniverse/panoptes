class Api::V1::TutorialsController < Api::ApiController
  doorkeeper_for :update, :create, :destroy, scopes: [:project]

  resource_actions :default

  schema_type :json_schema

  before_filter :set_language_from_header, only: [:index]

  protected

  def set_language_from_header
    params[:language] = "en"
  end
end
