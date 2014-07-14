class RegistrationsController < Devise::RegistrationsController
  def create
    respond_to do |format|
      format.json { create_from_json }
      format.html { super }
    end
  end

  private

  def create_from_json
    build_resource(sign_up_params)
    resource_saved = resource.save
    yield resource if block_given?
    status, content = if resource_saved
      [ :created, UserSerializer.resource(resource) ]
      sign_in resource, event: :authentication
    else
      [ :unprocessable_entity, {} ]
    end
    clean_up_passwords resource
    render status: status, json: content
  end 
end
