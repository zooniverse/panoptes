class Api::V1::SubjectSetImportsController < Api::ApiController
  require_authentication :create, scopes: [:project]

  resource_actions :index, :show, :create

  schema_type :json_schema

  def build_resource_for_create(create_params)
    super do |body_params, link_params|
      body_params[:user_id] = api_user.id
    end
  end
end
