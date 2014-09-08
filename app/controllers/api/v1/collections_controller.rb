class Api::V1::CollectionsController < Api::ApiController
  before_filter :require_login, only: [:create, :update, :destroy]
  doorkeeper_for :create, :update, :destroy, scopes: [:collection]
  access_control_for :create, :update, :destroy, resource_class: Collection
  
  alias_method :collection, :controlled_resource

  def show
    render json_api: serializer.resource(params, visible_scope)
  end

  def index
    render json_api: serializer.page(params, visible_scope)
  end

  protected

  def create_resource
    collection = Collection.new(create_params)
    collection.owner = owner
    return collection if collection.save!
  end

  def create_params
    params.require(:collections)
      .permit(:name, :display_name, :project_id)
  end

  def update_params
    p params
    params.require(:collections)
      .permit(:name, :display_name, links: :subjects)
  end
end
