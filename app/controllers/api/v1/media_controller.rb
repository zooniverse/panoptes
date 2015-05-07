class Api::V1::MediaController < Api::ApiController
  doorkeeper_for :update, :create, :destroy, scopes: [:medium]
  resource_actions :default

  schema_type :strong_params

  allowed_params :create, :content_type, :external_link
  allowed_params :update, :content_type

  def index
    @controlled_resources = Medium.where(id: controlled_resource.send(media_name).id)
    super
  end

  def show
    raise NotImplementedError
  end

  def update
    raise NotImplementedError
  end

  def destroy
    raise NotImplementedError
  end

  def create
    @controlled_resources = api_user.do(:update)
      .to(resource_class, scope_context)
      .with_ids(resource_ids)
      .scope

    check_controller_resources

    assoc = resource_class.reflect_on_association(media_name)
    created = case assoc.macro
              when :has_one
                if old_resource = controlled_resource.send(media_name)
                  old_resource.destroy
                end
                controlled_resource.send("create_#{media_name}", create_params)
              when :has_many
                controlled_resource.send(media_name).create(create_params)
              end

    created_resource_response(created)
  end

  def link_header(resource)
    identifier = if media_name == media_name.singularize
                   media_name
                 else
                   "/#{media_name}/#{resource.id}"
                 end

    "#{request.protocol}#{request.host_with_port}/api/#{resource_name}s/#{resource_ids}/#{identifier}"
  end

  def context
    case action_name
    when "update", "create"
      { post_urls: true }
    else
      { }
    end
  end

  def serializer
    MediumSerializer
  end

  def resource_sym
    :media
  end

  def resource_name
    @resource_name ||= params.keys.find{ |key| key.to_s.match(/_id/) }[0..-4]
  end

  def media_name
    params[:media_name]
  end

  private
  def resource_scope(resources)
    return resources if resources.is_a?(ActiveRecord::Relation)
    Medium.where(id: resources.try(:id) || resources.map(&:id))
  end
end
