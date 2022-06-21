class Api::V1::MediaController < Api::ApiController
  include JsonApiController::PunditPolicy
  include PolymorphicResourceScope

  polymorphic_column :linked

  require_authentication :update, :create, :destroy, scopes: [:medium]

  resource_actions :default

  schema_type :json_schema

  def schema_class(action)
    "medium_#{ action }_schema".camelize.constantize
  end

  def index
    if one_association?
      # generate the etag here as we use the index route for linked media has_one relations
      headers['ETag'] = gen_etag(controlled_resources.to_a)
      render json_api: serializer.page(params, controlled_resources, context)
    else
      super
    end
  end

  def create
    check_polymorphic_controller_resources

    created_media_resource = Medium.transaction(requires_new: true) do
      if many_association?
        polymorphic_controlled_resourse.send(media_name).create!(create_params)
      else
        if (old_resource = polymorphic_controlled_resourse.send(media_name))
          old_resource.destroy
        end
        polymorphic_controlled_resourse.send("create_#{media_name}!", create_params)
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
    when /\A(classifications|subjects)_export\z/
      :update
    else
      super
    end
  end

  private

  def raise_no_resources_error
    raise Api::NoMediaError.new(
      media_name,
      polymorphic_klass_name,
      polymorphic_ids,
      params[:id]
    )
  end

  def association_reflection
    @association_reflection ||= polymorphic_klass.reflect_on_association(media_name)
  end

  def one_association?
    @one_association ||= association_reflection.macro == :has_one
  end

  def many_association?
    @many_association ||= association_reflection.macro == :has_many
  end

  # locate the only the linked media type if it's supplied as a param (via routes)
  def controlled_resources
    @controlled_resources ||= if params[:media_name]
                                super.where(type: singular_linked_media_type)
                              else
                                super
                              end
  end

  # attached images have where(type: "tutorial_attached_image") } filters
  # so these has_many relations need to be singular types
  def singular_linked_media_type
    "#{polymorphic_klass_name}_#{params[:media_name]}".singularize
  end
end
