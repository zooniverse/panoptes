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
      resource.valid? if resource.errors.empty?
      response_body = {}
      unless resource.errors.empty?
        report_error(resource.id, resource_params) if resource.persisted?
        response_body.merge!(error_response(resource.errors.full_messages.join(", ")))
      end
      respond_to_request(response_body.empty?, response_body)
    end

    def create_from_json
      resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?
      status = resource_params["email"].present? && successfully_sent?(resource)
      respond_to_request(status)
    end

    def respond_to_request(action_status, body={})
      response_status = action_status ? :ok : :unprocessable_entity
      render status: response_status, json: body
    end

    def error_response(msg)
      { errors: [ message: msg ] }
    end

    def report_error(resource_id, params)
      match = params["password"] == params["password_confirmation"]
      length = params["password"].length
      #token is valid if the resource is persisted
      Honeybadger.notify(
        error_class:   "Reset password error",
        error_message: "Could not reset user password",
        context: {
          user_id: resource_id,
          password_match: match,
          password_length: length
        }
      )
    end
end
