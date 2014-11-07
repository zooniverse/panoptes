class Api::V1::MembershipsController < Api::ApiController
  include JsonApiController

  before_filter :require_login
  doorkeeper_for :all, scopes: [:group]
  resource_actions :index, :show, :create, :update, :deactivate

  allowed_params :create, links: [:user, :user_group]
  allowed_params :update, :state

  alias_method :membership, :controlled_resource

  protected

  def build_resource_for_update(update_params)
    update_params[:state] = Membership.states[update_params[:state]]
    super(update_params)
  end
  
  def to_disable
    [membership]
  end
end
