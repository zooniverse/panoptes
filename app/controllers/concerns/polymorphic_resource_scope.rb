module PolymorphicResourceScope
  extend ActiveSupport::Concern

  module ClassMethods
    def polymorphic_column(column_name)
      @polymorphic_column ||= column_name
    end

    def polymorphic_column_name
      @polymorphic_column
    end
  end

  private

  def polymorphic_column_name
    self.class.polymorphic_column_name
  end

  def controlled_resources
    return @controlled_resources if @controlled_resources

    resource_scope = resource_class.where(
      "#{polymorphic_column_name}_id" => polymorphic_controlled_resourses.select(:id),
      "#{polymorphic_column_name}_type" => polymorphic_klass
    )
    if params.key?(:id)
      resource_scope = resource_scope.where(id: params[:id])
    end
    @controlled_resources = resource_scope
  end

  def polymorphic_controlled_resourses
    @polymorphic_controlled_resourses ||=
      find_controlled_resources(
        polymorphic_klass,
        polymorphic_ids,
        controlled_scope
      )
  end

  # All users can create all resources by default,
  # to be sure they can create an associated resource we test
  # they can update the linked resource instead of :create
  # otherwise default to normal behaviour
  def controlled_scope
    if action_name == "create"
      :update
    else
      action_name.to_sym
    end
  end
  
  def polymorphic_controlled_resourse
    @polymorphic_controlled_resourse ||= @polymorphic_controlled_resourses.first
  end

  def polymorphic_klass_name
    @polymorphic_klass_name ||= params.keys.find do |key|
      key.to_s.match(/_id/)
    end[0..-4]
  end

  def polymorphic_klass
    @polymorphic_klass ||= polymorphic_klass_name.camelize.constantize
  end

  def polymorphic_ids(param_name=polymorphic_klass_name)
    return @polymorphic_ids if @polymorphic_ids
    ids_from_params = params["#{param_name}_id"] || ''
    @polymorphic_ids = array_id_params(ids_from_params)
  end

  # check the user can update the linked polymorphic resource
  # so they can create a linked polymorphic resource for it
  # e.g. A user wants link a background media resource to Project.where(id: 1)
  def check_polymorphic_controller_resources
    unless polymorphic_controlled_resourses.exists?
      raise_no_resources_error
    end
  end

  def _resource_ids
    return params["#{ polymorphic_klass_name }_id"] if params["#{ polymorphic_klass_name }_id"]

    if respond_to?(:resource_name) && params.has_key?("#{ resource_name }_id")
      params["#{ resource_name }_id"]
    elsif params.has_key?(:id)
      params[:id]
    else
      ''
    end
  end

  def no_resources_error_message
    "Could not find #{polymorphic_klass_name} #{controller_name} with #{no_resources_message_ids}"
  end

  def check_controller_resources
    raise_no_resources_error unless resources_exist?
  end

  def resources_exist?
    resource_ids.blank? ? true : controlled_resources.exists?
  end

  def controlled_resource
    @controlled_resource ||= controlled_resources.first
  end

  def find_controlled_resources(controlled_class, controlled_ids, action=controlled_scope)
    api_user.scope(klass: controlled_class,
                   action: action,
                   ids: controlled_ids,
                   context: scope_context,
                   add_active_scope: add_active_resources_scope)
  end

  def raise_no_resources_error
    raise JsonApiController::AccessDenied, no_resources_error_message
  end

  def no_resources_message_ids
    if resource_ids.is_a?(Array)
      "ids='#{resource_ids.join(',')}'"
    else
      "id='#{resource_ids}'"
    end
  end

  def resource_ids
    @resource_ids ||= array_id_params(_resource_ids)
  end

  def array_id_params(string_id_params)
    ids = string_id_params.split(',')
    if ids.length < 2
      ids.first
    else
      ids
    end
  end

  def scope_context
    {}
  end

  def add_active_resources_scope
    true
  end
end
