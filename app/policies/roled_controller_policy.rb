class RoledControllerPolicy
  attr_reader :api_user, :resource_class, :resource_name, :action_name, :params, :scope_context, :add_active_resources_scope
  
  def initialize(api_user, resource_class, resource_name, action_name, params, scope_context: {}, add_active_resources_scope: true, **kwargs)
    @api_user = api_user
    @resource_class = resource_class
    @resource_name = resource_name
    @action_name = action_name
    @params = params
    @scope_context = scope_context
    @add_active_resources_scope = add_active_resources_scope
  end

  def resources_exist?
    resource_ids.blank? ? true : scope.exists?
  end

  def scope
    @scope ||= api_user.scope(klass: resource_class,
                              action: controlled_scope,
                              ids: resource_ids,
                              context: scope_context,
                              add_active_scope: add_active_resources_scope)
  end

  def resource_ids
    @resource_ids ||= array_id_params(_resource_ids)
  end

  private

  def controlled_scope
    action_name.to_sym
  end

  def array_id_params(string_id_params)
    ids = string_id_params.split(',')
    if ids.length < 2
      ids.first
    else
      ids
    end
  end

  def _resource_ids
    if resource_name.present? && params.has_key?("#{ resource_name }_id")
      params["#{ resource_name }_id"]
    elsif params.has_key?(:id)
      params[:id]
    else
      ''
    end
  end
end
