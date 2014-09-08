class Api::V1::GroupsController < Api::ApiController
  include DeactivatableResource

  before_filter :require_login, only: [:create, :update, :destroy]
  doorkeeper_for :index, :create, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:group]
  access_control_for :update, :create, :destroy, resource_class: UserGroup
  
  alias_method :user_group, :controlled_resource

  def show
    render json_api: serializer.resource(params)
  end

  def index
    render json_api: serializer.page(params)
  end

  def update
  end

  private

  def create_resource
    group = UserGroup.new(user_group_params)
    
    ActiveRecord::Base.transaction do
      group.display_name ||= group.name
      group.owner_name = OwnerName.new(name: group.name,
                                       resource: group)
      group.save!
      Membership.create(user: api_user.user,
                        user_group: group,
                        state: :active,
                        roles: ["group_admin"])
    end
    
    return group if group.persisted?
  end

  def to_disable
    [ user_group ] |
      user_group.projects |
      user_group.collections |
      user_group.memberships
  end

  def user_group_params
    params.require(:user_groups).permit(:name, :display_name)
  end

  def serializer
    UserGroupSerializer
  end
end
