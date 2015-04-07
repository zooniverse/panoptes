class PasswordsController < Devise::PasswordsController
  def create
    respond_to do |format|
      format.json_api { create_from_json }
      format.html { super }
    end
  end

  def update
    respond_to do |format|
      format.json_api { update_from_json }
      format.html { super }
    end
  end

  private

    def update_from_json
      resource = resource_class.reset_password_by_token(resource_params)
      yield resource if block_given?
      respond_to_request(resource.errors.empty?)
    end

    def create_from_json
      status = false
      if able_to_reset_password?
        resource = resource_class.send_reset_password_instructions(resource_params)
        yield resource if block_given?
        status = successfully_sent?(resource)
      end
      respond_to_request(status)
    end

    def respond_to_request(action_status)
      response_status = action_status ? :ok : :unprocessable_entity
      render status: response_status, json: {}
    end

    def able_to_reset_password?
      if user = resource_class.find_for_authentication(resource_params)
        disabled_or_omni_auth = user.disabled? || user.email.blank?
        !disabled_or_omni_auth
      else
        false
      end
    end
end
