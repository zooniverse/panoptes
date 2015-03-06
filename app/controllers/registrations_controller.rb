class RegistrationsController < Devise::RegistrationsController
  include JSONApiRender

  def create
    respond_to do |format|
      format.json { create_from_json }
      format.html do
        head :unsupported_media_type
      end
    end
  end

  private

  def create_from_json
    build_resource(sign_up_params)
    resource_saved = create_zoo_user(resource) && resource.save
    yield resource if block_given?
    status, content = registrations_response(resource_saved)
    clean_up_passwords resource
    render status: status, json_api: content
  end

  def build_resource(sign_up_params)
    super(sign_up_params)
    resource.build_identity_group
  end

  def create_zoo_user(resource)
    if resource.valid? && ZooHomeConfiguration.use_zoo_home?
      zu = ZooniverseUser.create_from_user(resource)
      if zu.persisted?
        true
      else
        zu.errors.each do |attr, errors|
          resource.errors.add(attr, errors)
        end
        false
      end
    end
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
end
