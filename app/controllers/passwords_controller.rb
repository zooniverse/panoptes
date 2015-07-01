class PasswordsController < Devise::PasswordsController
  def create
    respond_to do |format|
      format.json { create_from_json }
      format.html { super }
    end
  end

  def update
    respond_to do |format|
      format.json { update_from_json }
      format.html { super }
    end
  end

  def edit
    if Panoptes.password_reset_redirect
      redirect_to "#{Panoptes.password_reset_redirect}?reset_password_token=#{params[:reset_password_token]}"
    else
      super
    end
  end

  private

    def update_from_json
      resource = resource_class.reset_password_by_token(resource_params)
      yield resource if block_given?
      respond_to_request(resource.errors.empty?)
    end

    def create_from_json
      resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?
      status = resource_params["email"].present? && successfully_sent?(resource)
      respond_to_request(status)
    end

    def respond_to_request(action_status)
      response_status = action_status ? :ok : :unprocessable_entity
      render status: response_status, json: {}
    end
end
