class RoledControllerPolicy
  attr_reader :api_user, :resource_class, :resource_ids, :scope_context, :add_active_resources_scope

  def initialize(api_user, resource_class, resource_ids, scope_context: {}, add_active_resources_scope: true, **kwargs)
    @api_user = api_user
    @resource_class = resource_class
    @resource_ids = resource_ids
    @scope_context = scope_context
    @add_active_resources_scope = add_active_resources_scope
  end

  def scope_for(action)
    @scope ||= api_user.scope(klass: resource_class,
                              action: action,
                              ids: resource_ids,
                              context: scope_context,
                              add_active_scope: add_active_resources_scope)
  end
end
