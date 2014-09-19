class Api::V1::MembershipsController < Api::ApiController
  include JsonApiController

  before_filter :require_login
  doorkeeper_for :all, scopes: [:group]
  access_control_for :create, :update, :destroy

  resource_actions :index, :show, :create, :update, :deactivate

  request_template :create, links: [:user, :user_group]
  request_template :update, :state

  alias_method :membership, :controlled_resource

  protected
  
  def to_disable
    [membership]
  end
end
