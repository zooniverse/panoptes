class Api::V1::CollectionsController < Api::ApiController
  doorkeeper_for :all

  def show
    collection = Collection.find params[:id]
    api_user.do(:read).to(collection).as(owner_from_params)
      .call { render json_api: CollectionSerializer.resource(collection) }
  end

  def index
    visible_scope = Collection.visible_to(api_user)
    render json_api: CollectionSerializer.page(params, visible_scope)
  end

  def update

  end

  def create
    collection = api_user.do(:create).to(Collection).as(owner_from_params)
      .call { |owner| create_for_owner(owner) }
    json_api_render(201,
                    CollectionSerializer.resource(collection),
                    api_collection_url(collection) )
  end
  def destroy
    collection = Collection.find params[:id]
    api_user.do(:destroy).to(collection).as(owner_from_params)
      .call { collection.destroy! }
    deleted_resource_response
  end

  def creation_params
    params.require(:collection).permit :name, :display_name, :project_id
  end

  def create_for_owner(owner)
    collection = Collection.new creation_params
    collection.owner = owner
    return collection if collection.save!
  end
end
