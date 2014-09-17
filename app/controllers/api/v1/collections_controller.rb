class Api::V1::CollectionsController < Api::ApiController
  include JsonApiController
  
  before_filter :require_login, only: [:create, :update, :destroy]
  doorkeeper_for :create, :update, :destroy, scopes: [:collection]
  access_control_for :create, :update, :destroy

  resource_actions :default

  request_template :create, :name, :display_name,
    links: [ :project, subjects:  [], owner: polymorphic ]

  request_template :update, :name, :display_name, links: [ subjects: [] ]
  
  protected

  def create_resource(create_params)
    create_params[:links][:owner] = owner || api_user.user
    super(create_params)
  end
end

