class RegistrationsController < Devise::RegistrationsController
  include JSONApiRender

  def create
    respond_to do |format|
      format.json do
        create_from_json { |resource| subscribe_to_emails(resource) }
      end
      format.html do
        super { |resource| subscribe_to_emails(resource) }
      end
    end
  end

  def update
    respond_to do |format|
      format.json { update_from_json }
      format.html { super }
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
      render json: {}, status: :no_content
    else
      render json: {errors: [{message: "Current password was incorrect, or new passwords did not match"}]}, status: :unprocessable_entity
    end
  rescue ActionController::UnpermittedParameters => e
    render json: {errors: [{message: e.message}]}, status: :unprocessable_entity
  end

  def build_resource(sign_up_params)
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

  def subscribe_to_emails(resource)
    if resource.persisted? && resource.global_email_communication
      SubscribeWorker.perform_async(resource.email)
    end
  end
end
