class RegistrationsController < Devise::RegistrationsController
  include JSONApiRender

  def create
    respond_to do |format|
      p format
      format.json_api { create_from_json }
      format.html { super }
    end
  end

  private

  def create_from_json
    build_resource(sign_up_params)
    resource_saved = resource.save
    yield resource if block_given?
    status, content = if resource_saved
      sign_in resource, event: :authentication
      [ :created, UserSerializer.resource(resource) ]
    else
      [ :unprocessable_entity, {} ]
    end
    clean_up_passwords resource
    render status: status, json_api: content
  end 
end
