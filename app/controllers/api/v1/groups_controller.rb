class Api::V1::GroupsController < Api::ApiController
  include DeactivatableResource
  
  doorkeeper_for :index, :create, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:group]
  access_control_for :update, :create, :destroy, resource_class: UserGroup
  
  alias_method :user_group, :controlled_resource

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
    json_api_render(201,
                    UserGroupSerializer.resource(group),
                    api_group_url(group) )
  end

  private

  def to_disable
    [ user_group ] |
      user_group.projects |
      user_group.collections |
      user_group.memberships
  end

  def user_group_params
    params.require(:user_group).permit(:name, :display_name)
  end
end
