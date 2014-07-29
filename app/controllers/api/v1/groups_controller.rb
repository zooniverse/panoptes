class Api::V1::GroupsController < Api::ApiController
  doorkeeper_for :index, :create, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:group]

  def show
    render json_api: UserGroupSerializer.resource(params)
  end

  def index
    render json_api: UserGroupSerializer.page(params)
  end

  def update
  end

  def create
    group = UserGroup.new(user_group_params)
    group.display_name ||= group.name
    group.owner_name = OwnerName.new(name: group.name, resource: group)
    group.save!
    json_api_render( 201,
                     UserGroupSerializer.resource(group),
                     api_group_url(group) )
  end

  def destroy
    user_group = UserGroup.find(params[:id])
    Activation.disable_instances!([ user_group ] | user_group.projects | user_group.memberships)
    deleted_resource_response
  end

  private

  def user_group_params
    params.require(:user_group).permit(:name, :display_name)
  end
end
