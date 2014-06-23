class Api::V1::PasswordsController < Devise::PasswordsController

  include JSONApiRender

  def create
    resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?
    status = reset_status(resource) { |resource| successfully_sent?(resource) }
    render status: status, json_api: {}
  end

  def update
    resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?
    status = reset_status(resource) { |resource| resource.errors.empty? }
    render status: status, json_api: {}
  end

  private

    def reset_status(resource, &block)
      success_event = yield resource
      success_event ? :ok : :unprocessable_entity
    end
end
