class Api::V1::SubjectSetsController < Api::ApiController
  doorkeeper_for :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :json_schema

  protected

  def build_resource_for_create(create_params)
    super do |_, link_params|
      if collection_id = link_params.delete("collection")
        if collection = Collection.scope_for(:show, api_user).where(id: collection_id).first
          link_params["subjects"] = collection.subjects
        else
          raise ActiveRecord::RecordNotFound, "No Record Found for Collection with id: #{collection_id}"
        end
      end
    end
  end
end
