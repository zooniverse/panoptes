class Api::V1::CollectionsController < Api::ApiController
  doorkeeper_for :all

  def show
    collection = Collection.find params[:id]
    render json_api: CollectionSerializer.resource(params)
  end

  def index
    render json_api: CollectionSerializer.page(params)
  end

  def update

  end

  def create
    collection = Collection.new creation_params
    collection.owner = current_resource_owner
    collection.save!
    json_api_render( 201,
                     CollectionSerializer.resource(collection),
                     api_collection_url(collection) )
  end

  def destroy
    collection = Collection.find params[:id]
    collection.destroy!
    deleted_resource_response
  end

  def creation_params
    params.require(:collection).permit :name, :display_name, :project_id
  end
end
