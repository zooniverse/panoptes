class Api::V1::MembershipsController < Api::ApiController
  include JsonApiController

  before_filter :require_login
  doorkeeper_for :all, scopes: [:group]
  access_control_for :create, :update, :destroy

  resource_actions :index, :show, :create, :update, :deactivate

  allowed_params :create, links: [:user, :user_group]
  allowed_params :update, :state

  alias_method :membership, :controlled_resource

  protected
  
  def to_disable
    [membership]
  end
end
