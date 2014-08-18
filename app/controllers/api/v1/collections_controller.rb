class Api::V1::CollectionsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json_api: CollectionSerializer.resource(params, visible_scope(api_user))
  end

  def index
    render json_api: CollectionSerializer.page(params, visible_scope(api_user))
  end

  def update
    # TODO 
  end

  def create
    owner = owner_from_params || api_user.user
    collection = create_for_owner(owner)
    json_api_render(201,
                    CollectionSerializer.resource(collection),
                    api_collection_url(collection) )
  end

  def destroy
    collection.destroy!
    deleted_resource_response
  end

  alias_method :collection, :controlled_resource
  
  access_control_for :create, :update, :destroy, resource_class: Collection

  protected

  def creation_params
    params.require(:collection).permit :name, :display_name, :project_id
  end

  def create_for_owner(owner)
    collection = Collection.new creation_params
    collection.owner = owner
    return collection if collection.save!
  end
end
