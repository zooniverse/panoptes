class Api::V1::CollectionsController < Api::ApiController
  include JsonApiController
  
  doorkeeper_for :create, :update, :destroy, scopes: [:collection]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :name, :display_name,
    links: [ :project, subjects:  [], owner: polymorphic ]

  allowed_params :update, :name, :display_name, links: [ subjects: [] ]
  
  protected

  def build_resource_for_create(create_params)
    create_params[:links][:owner] = owner || api_user.user
    super(create_params)
  end
end

