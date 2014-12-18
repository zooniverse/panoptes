class Api::V1::SubjectSetsController < Api::ApiController
  doorkeeper_for :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :json_schema

  protected

  def build_resource_for_create(create_params)
    super do |_, link_params|
      if collection_id = link_params.delete("collection")
        link_params["subjects"] = Collection.scope_for(:show, api_user)
                                  .find(collection_id).subjects
      end
    end
  end
end
