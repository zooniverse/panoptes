class Api::V1::MediaController < Api::ApiController
  require_authentication :update, :create, :destroy, scopes: [:medium]

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
    check_polymorphic_controller_resources

    created_media_resource = Medium.transaction(requires_new: true) do
      begin
        if association_numeration == :collection
          polymorphic_controlled_resourse.send(media_name).create!(create_params)
        else
          if old_resource = polymorphic_controlled_resourse.send(media_name)
            old_resource.destroy
          end
          polymorphic_controlled_resourse.send("create_#{media_name}!", create_params)
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

  # @EXTRACT polymorphic helper
  def association_reflection
    polymorphic_klass.reflect_on_association(media_name)
  end

  # @EXTRACT polymorphic helper
  def association_numeration
    case association_reflection.macro
    when :has_one
      :single
    when :has_many
      :collection
    end
  end

  def controlled_resources
    return @controlled_resources if @controlled_resources

    linked_media_scope = resource_class.where(
      linked_id: polymorphic_controlled_resourses.select(:id),
      linked_type: polymorphic_klass
    )
    if params.key?(:id)
      linked_media_scope = linked_media_scope.where(id: params[:id])
    end

    @controlled_resources = linked_media_scope
  end

  # @EXTRACT polymorphic helper
  def polymorphic_controlled_resourses
    @polymorphic_controlled_resourses ||= find_controlled_resources(polymorphic_klass, polymorphic_ids)
  end

  # @EXTRACT polymorphic helper
  def polymorphic_controlled_resourse
    @polymorphic_controlled_resourse ||= @polymorphic_controlled_resourses.first
  end

  # @EXTRACT polymorphic helper
  def polymorphic_klass_name
    @polymorphic_klass_name ||= params.keys.find{ |key| key.to_s.match(/_id/) }[0..-4]
  end

  # @EXTRACT polymorphic helper
  def polymorphic_klass
    @polymorphic_klass ||= polymorphic_klass_name.camelize.constantize
  end

  # @EXTRACT polymorphic helper
  def polymorphic_ids
    return @polymorphic_ids if @polymorphic_ids
    polymorphic_ids = if params.has_key?("#{ polymorphic_klass_name }_id")
                        params["#{ polymorphic_klass_name }_id"]
                      else
                        ''
                      end.split(',')
    @polymorphic_ids = polymorphic_ids.length < 2 ? polymorphic_ids.first : polymorphic_ids
  end

  # @EXTRACT polymorphic helper

  # check the user can update the linked polymorphic resource
  # so they can create a linked polymorphic resource for it
  # e.g. A user wants link a background media resource to Project.where(id: 1)
  def check_polymorphic_controller_resources
    raise_no_resources_error unless polymorphic_controlled_resourses.exists?
  end

  # @EXTRACT polymorphic helper
  def _resource_ids
    params["#{ polymorphic_klass_name }_id"] || super
  end

  # @EXTRACT polymorphic helper
  def raise_no_resources_error
    raise Api::NoMediaError.new(media_name, polymorphic_klass_name, polymorphic_ids, params[:id])
  end

  def send_aggregation_ready_email
    return unless params[:media_name] == "aggregations_export"
    if controlled_resource.metadata.try(:[], "state") == "ready"
      AggregationDataMailerWorker.perform_async(controlled_resource.id)
    end
  end
end
