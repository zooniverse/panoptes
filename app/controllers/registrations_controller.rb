class RegistrationsController < Devise::RegistrationsController
  include JSONApiRender

  def create
    respond_to do |format|
      format.json do
        create_from_json
      end
      format.html do
        super
      end
    end
  end

  def update
    respond_to do |format|
      format.json { update_from_json }
      format.html { super }
    end
  end

  def destroy
    if current_user.valid_password?(params[:user][:current_password])
      UserInfoScrubber.scrub_personal_info!(current_user)
      Activation.disable_instances!([current_user])
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      set_flash_message! :notice, :destroyed
      respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
    else
      flash[:delete_alert] = "Incorrect password"
      render action: :edit
    end
  end

  private

  def create_from_json
    build_resource(sign_up_params)
    resource_saved = resource.save
    yield resource if block_given?
    status, content = registrations_response(resource_saved)
    clean_up_passwords resource
    render status: status, json_api: content
  end

  def update_from_json
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    if resource.update_with_password(account_update_params)
      revoke_access_tokens!
      UserInfoChangedMailerWorker.perform_async(resource.id, "password")
      render json: {}, status: :no_content
    else
      render json: {errors: [{message: "Current password was incorrect, or new passwords did not match"}]}, status: :unprocessable_entity
    end
  rescue ActionController::UnpermittedParameters => e
    render json: {errors: [{message: e.message}]}, status: :unprocessable_entity
  end

  def build_resource(sign_up_params={})
    super(sign_up_params)
    resource.display_name = resource.login if resource.display_name.blank?
    resource.project_email_communication = resource.global_email_communication
    resource.build_identity_group
  end

  def registrations_response(resource_saved)
    if resource_saved
      sign_in resource, event: :authentication
      resource_scope = resource.class.where(id: resource.id)
      [ :created, UserSerializer.resource({}, resource_scope, { include_private: true }) ]
    else
      response_body = {}
      if resource && !resource.valid?
        response_body.merge!({ errors: [ message: resource.errors ] })
      end
      [ :unprocessable_entity, response_body ]
    end
  end

  def revoke_access_tokens!
    application_ids_to_revoke = oauth_application_ids_to_revoke
    return if application_ids_to_revoke.empty?

    Doorkeeper::AccessToken.revoke_all_for(
      application_ids_to_revoke,
      resource
    )
  end

  def oauth_application_ids_to_revoke
    if params.key?(:revoke_all_tokens)
      # revoke tokens for ALL known oauth applications in the system
      Doorkeeper::Application.pluck(:id)
    else
      [doorkeeper_token&.application_id]
    end
  end
end
