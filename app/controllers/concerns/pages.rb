module Pages
  extend ActiveSupport::Concern

  included do
    resource_actions :default

    schema_type :strong_params

    allowed_params :create, :url_key, :title, :content, :language
    allowed_params :update, :url_key, :title, :content, :language

    before_filter :set_language_if_missing, only: [:index]

    # Methods defined here in order to avoid being overridden by resource modules
    define_method(:link_header) do |resource|
      resource = resource.first
      send(:"api_#{ resource_name }_url", id: resource.id, "#{parent_resource}_id": resource_id)
    end

    define_method(:build_resource_for_create) do |create_params|
      create_params[:links] ||= {}
      create_params[:links][parent_resource] = resource_id
      super create_params
    end

    require_authentication :update, :create, :destroy, scopes: [:"#{self::PARENT_RESOURCE}"]
  end

  def controlled_resources
    @controlled_resouces ||= super.where("#{parent_resource}": resource_id)
  end

  def parent_resource
    self.class::PARENT_RESOURCE
  end

  def resource_name
    @resource_name ||= controller_name.singularize
  end

  def resource_id
    params[:"#{parent_resource}_id"]
  end

  protected

  def set_language_if_missing
    params[:language] ||= "en"
  end

  def serializer
    @serializer ||= "#{resource_name.camelize}Serializer".constantize
  end
end
