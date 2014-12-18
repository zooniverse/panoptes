module RolesController
  extend ActiveSupport::Concern

  included do
    prepend_before_filter :require_login
    resource_actions :index, :show, :create, :update

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

  module BuildOverride
    def build_resource_for_create(create_params)
      create_params[:links][:user_group] = User.find(create_params[:links].delete(:user))
                                         .identity_group
      create_params[:links][:resource] = { type: enrolled_resource.pluralize,
                                         id: create_params[:links].delete(enrolled_resource) }
      super(create_params)
    end
  end
end
