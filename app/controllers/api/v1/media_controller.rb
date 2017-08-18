class Api::V1::MediaController < Api::ApiController
  require_authentication :update, :create, :destroy, scopes: [:medium]

  # ensure these before actions register before the resource_actions DSL
  # so that the precondition checks are testing the correct controlled_resources
  before_action :media_parental_controlled_resources, only: %i(index show update destroy)
  before_action :media_controlled_resources, only: %i(index show update destroy)
  before_action :error_unless_exists, except: :create

  resource_actions :default

  schema_type :json_schema

  def schema_class(action)
    "medium_#{ action }_schema".camelize.constantize
  end

  def index
    if association_numeration == :single
      #generate the etag here as we use the index route for linked media has_one relations
      headers['ETag'] = gen_etag(controlled_resources)
      render json_api: serializer.page(params, controlled_resources, context)
    else
      super
    end
  end

  def update
    super
    send_aggregation_ready_email
  end

  def create
    media_parental_create_resource_scope do
      check_controller_resources
    end

    created_media_resource = Medium.transaction(requires_new: true) do
      begin
        if association_numeration == :collection
          controlled_resource.send(media_name).create!(create_params)
        else
          if old_resource = controlled_resource.send(media_name)
            old_resource.destroy
          end
          controlled_resource.send("create_#{media_name}!", create_params)
        end
      end
    end

    created_resource_response(created_media_resource)
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

  # this wires up the polymorphic controller scope to load linked resource
  def resource_name
    @resource_name ||= params.keys.find{ |key| key.to_s.match(/_id/) }[0..-4]
  end

  def media_name
    params[:media_name]
  end

  def controlled_scope
    case media_name
    when /\A(classifications|subjects|aggregations)_export\z/
      :update
    else
      action_name.to_sym
    end
  end

  private

  def resource_scope(resources)
    return resources if resources.is_a?(ActiveRecord::Relation)
    Medium.where(id: resources.try(:id) || resources.map(&:id))
  end

  def association_reflection
    resource_class.reflect_on_association(media_name)
  end

  def association_numeration
    case association_reflection.macro
    when :has_one
      :single
    when :has_many
      :collection
    end
  end

  # store the original parental contolling scope wired up via the
  # resource params and the resource_name method
  # E.g project_id: 1 => Project is the controlled resource
  def media_parental_controlled_resources
    @media_parental_controlled_resources ||= controlled_resources
  end

  # override the controlled resources to handle the polymorphic media lookup
  # from the different routes paths, e.g. /api/workflows/:id/attached_images
  # will lookup the linked attached_images media for the workflow :id
  def media_controlled_resources
    linked_media_scope = association_reflection.klass.where(
      linked_id: media_parental_controlled_resources.select(:id),
      linked_type: resource_class.name
    )
    if params.key?(:id)
      linked_media_scope = linked_media_scope.where(id: params[:id])
    end
    @controlled_resources = linked_media_scope
    @controlled_resource = nil
  end

  def error_unless_exists
    unless controlled_resources && controlled_resources.exists?
      raise Api::NoMediaError.new(media_name, resource_name, resource_ids, params[:id])
    end
  end

  # check the user can update the linked parental resource
  # so they can create a linked media resource for it
  def media_parental_create_resource_scope
    @controlled_resources = api_user.do(:update)
    .to(resource_class, scope_context)
    .with_ids(resource_ids)
    .scope
    yield if block_given?
  end

  def send_aggregation_ready_email
    return unless params[:media_name] == "aggregations_export"
    if controlled_resource.metadata.try(:[], "state") == "ready"
      AggregationDataMailerWorker.perform_async(controlled_resource.id)
    end
  end
end
