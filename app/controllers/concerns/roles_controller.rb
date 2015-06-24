module RolesController
  extend ActiveSupport::Concern

  included do
    resource_actions :default
    schema_type :strong_params

    before_filter :format_filter_params, only: :index
    before_filter :filter_by_user_id, only: :index

    include BuildOverride
  end

  def enrolled_resource
    resource_name.split("_").first
  end

  def serializer
    @serializer ||= "#{resource_name.camelize}Serializer".constantize
  end

  def resource_class
    AccessControlList
  end

  def scope_context
    { resource_type: enrolled_resource.camelize.constantize }
  end

  def format_filter_params
    if filter = params.delete("#{enrolled_resource}_id")
      params[:resource_id] = filter
      params[:resource_type] = enrolled_resource.capitalize
    end
  end

  def filter_by_user_id
    if user_ids = params.delete(:user_id).try(:split, ',')
      @controlled_resources = controlled_resources.joins(user_group: :memberships)
        .where(memberships: {user_id: user_ids, identity: true})
    end
  end

  module BuildOverride
    def build_resource_for_create(create_params)
      user_id = create_params[:links].delete(:user)

      ig = User.where(id: user_id).first
      .try(:identity_group)

      raise Api::NoUserError, "No User with id: #{user_id} exists" unless ig

      create_params[:links][:user_group] = ig
      create_params[:links][:resource] =
        { type: enrolled_resource.pluralize,
         id: create_params[:links].delete(enrolled_resource) }
      super(create_params)
    end
  end
end
