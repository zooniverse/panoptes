class SessionsController < Devise::SessionsController
  include JSONApiRender

  def create
    respond_to do |format|
      format.html { super }
      format.json_api { create_from_json }
    end
  end

  def destroy
    respond_to do |format|
      format.html { super }
      format.json_api { destroy_from_json }
    end
  end

  private

  def create_from_json
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    yield resource if block_given?
    render status: 200, json_api: UserSerializer.resource(resource)
  end

  def destroy_from_json 
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    yield if block_given?
    head :no_content
  end
end
