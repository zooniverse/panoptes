class Api::V1::RegistrationsController < Devise::RegistrationsController

  include JSONApiRender

  def create
    build_resource(sign_up_params)
    resource_saved = resource.save
    yield resource if block_given?
    status, content = if resource_saved
      sign_up(resource_name, resource)
      [ :created, UserSerializer.resource(resource) ]
    else
      clean_up_passwords resource
      [ :unprocessable_entity, {} ]
    end
    render status: status, json_api: content
  end
end
