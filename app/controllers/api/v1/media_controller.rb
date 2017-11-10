class Api::V1::MediaController < Api::ApiController
  require_authentication :update, :create, :destroy, scopes: [:medium]
  resource_actions :default

  before_action :create_conditions, only: :create

  schema_type :json_schema

  def schema_class(action)
    "medium_#{ action }_schema".camelize.constantize
  end

  def index
    unless media.blank?
      @controlled_resources = media
      if association_numeration == :single
        #generate the etag here as we use the index route for linked media has_one relations
        headers['ETag'] = gen_etag(controlled_resources)
        render json_api: serializer.page(params, controlled_resources, context)
      else
        super
      end
    else
      raise Api::NoMediaError.new(media_name, resource_name, resource_ids)
    end
  end

  def show
    error_unless_exists
    set_controlled_resources
    super
  end

  def update
    error_unless_exists
    set_controlled_resources
    super
  end

  def destroy
    error_unless_exists
    set_controlled_resources
    super
  end

  def create
    created = if association_numeration == :collection
                controlled_resource.send(media_name).create!(create_params)
              else
                if old_resource = controlled_resource.send(media_name)
                  old_resource.destroy
                end
                controlled_resource.send("create_#{media_name}!", create_params)
              end
    created_resource_response(created)
  end

  def set_controlled_resources
    if association_numeration == :collection
      @controlled_resources = media.where(id: params[:id])
    else
      @controlled_resources = media
    end

  end

  def media
    return @media if @media
    linked_media = controlled_resource.send(media_name)
    @media = if linked_media && association_numeration == :single
               id = params[:id] ? params[:id] : linked_media.id
               linked_media.class.where(id: id)
             else
               linked_media
             end
  end

  def error_unless_exists
    unless media_exists?
      raise Api::NoMediaError.new(media_name, resource_name, resource_ids, params[:id])
    end
  end

  def link_header(resource)
    "#{request.protocol}#{request.host_with_port}/api#{resource.location}"
  end

  def context
    case action_name
    when "update", "create"
      { url_format: :put }
    else
      { url_format: :get }
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

  def controlled_scope
    case media_name
    when /\A(classifications|subjects)_export\z/
      :update
    else
      action_name.to_sym
    end
  end

  private

  def precondition_fails?
    query = if association_numeration == :single
              media
            else
              Medium.where(id: params[:id])
            end
    run_etag_validation(query)
  end

  def resource_scope(resources)
    return resources if resources.is_a?(ActiveRecord::Relation)
    Medium.where(id: resources.try(:id) || resources.map(&:id))
  end

  def association_numeration
    assoc = resource_class.reflect_on_association(media_name)
    case assoc.macro
    when :has_one
      :single
    when :has_many
      :collection
    end
  end

  def media_exists?
    return false unless media
    case association_numeration
    when :single
      media.exists?
    when :collection
      media.exists?(params[:id])
    end
  end

  def create_conditions
    @controlled_resources = api_user.do(:update)
    .to(resource_class, scope_context)
    .with_ids(resource_ids)
    .scope
    check_controller_resources
  end
end
