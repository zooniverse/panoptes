class RegistrationsController < Devise::RegistrationsController

  include JSONApiRender

  def create
    build_resource(sign_up_params)
    resource_saved = resource.save
    yield resource if block_given?
    status, content = if resource_saved
      [ :created, UserSerializer.resource(resource) ]
    else
      [ :unprocessable_entity, {} ]
    end
    clean_up_passwords resource
    render status: status, json_api: content
  end
end
