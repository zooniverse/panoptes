class RegistrationsController < Devise::RegistrationsController
  include JSONApiRender

  def create
    respond_to do |format|
      format.json { create_from_json }
      format.html do
        super
      end
    end
  end

  private

  def create_from_json
    build_resource(sign_up_params)
    if create_zoo_user(resource)
      resource_saved = resource.save
    end
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
    return true unless ZooHomeConfiguration.use_zoo_home?
    if resource.valid?
      zu = ZooniverseUser.create_from_user(resource)
      return true if zu.persisted?
      zu.errors.each do |attr, errors|
        resource.errors.add(attr, errors)
      end
      false
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
