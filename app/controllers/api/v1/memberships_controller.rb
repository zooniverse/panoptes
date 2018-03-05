class Api::V1::MembershipsController < Api::ApiController
  attr_reader :auth_scheme
  delegate :check_controller_resources,
    :controlled_resources,
    :controlled_resource,
    to: :auth_scheme

  prepend_before_filter :require_login
  require_authentication :all, scopes: [:group]

  before_action :setup_auth_scheme, except: :create
  before_action :check_controller_resources, except: :create

  resource_actions :index, :show, :create, :update, :deactivate
  schema_type :strong_params

  allowed_params :update, :state

  def create
    resources = resource_class.transaction(requires_new: true) do
      Array.wrap(params[:memberships]).map do |membership_params|
        operation.run!(membership_params)
      end
    end

    created_resource_response(resources)
  end

  private

  def setup_auth_scheme
    @auth_scheme = RoleControl::ControlledResources.new(
      self,
      add_active_resources_scope: false
    )
  end
end
