class Api::V1::PasswordsController < Devise::PasswordsController

  include JSONApiRender

  def create
    status = false
    if active_user?
      resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?
      status = successfully_sent?(resource)
    end
    respond_to_request(status)
  end

  def update
    resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?
    respond_to_request(resource.errors.empty?)
  end

  private

    def respond_to_request(action_status)
      response_status = action_status ? :ok : :unprocessable_entity
      render status: response_status, json_api: {}
    end

    def active_user?
      if user = resource_class.find_for_authentication(resource_params)
        !user.disabled?
      else
        false
      end
    end
end
