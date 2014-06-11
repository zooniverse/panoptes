class Api::V1::GroupsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: UserGroupSerializer.resource(params), content_type: api_content
  end

  def index
    render json: UserGroupSerializer.page(params), content_type: api_content
  end

  def update

  end

  def create

  end

  def destroy
    user_group = UserGroup.find(params[:id])
    Activation.disable_instances!([ user_group ] | user_group.projects | user_group.memberships)
    deleted_resource_response
  end
end
