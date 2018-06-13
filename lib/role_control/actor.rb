module RoleControl
  module Actor
    def scope(klass:, action:, ids: nil, context: {}, add_active_scope: true)
      scope = klass.scope_for(action, self, context)

      if add_active_scope && klass.respond_to?(:active)
        scope = scope.merge(klass.active)
      end

      if ids.present?
        scope = scope.where(id: ids).order(:id)
      end

      scope
    end
  end
end
