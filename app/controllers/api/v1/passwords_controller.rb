class Api::V1::PasswordsController < Devise::PasswordsController

  include JSONApiRender

  def create
    if resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?
    end
    render status: reset_create_status(resource), json_api: {}
  end

  private

    def reset_create_status(resource)
      return :bad_request unless resource
      successfully_sent?(resource) ? :ok : :unprocessable_entity
    end
end
