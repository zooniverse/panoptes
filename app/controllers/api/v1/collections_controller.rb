class Api::V1::CollectionsController < Api::ApiController
  doorkeeper_for :all
  access_control_for :create, :update, :destroy, resource_class: Collection
  
  alias_method :collection, :controlled_resource

  def show
    render json_api: serializer.resource(params, visible_scope(api_user))
  end

  def index
    render json_api: serializer.page(params, visible_scope(api_user))
  end

  def update
    # TODO 
  end

  protected

  def create_resource
    collection = Collection.new(create_params)
    collection.owner = owner
    return collection if collection.save!
  end

  def create_params
    params.require(:collection).permit(:name, :display_name, :project_id)
  end
end
