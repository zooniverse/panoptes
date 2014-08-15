module RoleControl
  class ActorRoleAssociation
    def intiailzie(actor_class, resource_class, role_association, other_associations=[])
      @actor = actor_class
      @resource = resource_class
      @association = role_association
      @extra_associations = other_associations
    end

    def scope(action, *args)
      args = [@assocation].concat(args)
      
      scope = actor_class.role_scope(action, *args)
        .merge(resource_class.role_scope(action, *args))
      
      @extra_associations.reduce(scope) do |assoc|
        scope.merge(assoc.role_scope(action, *args))
      end
    end
  end
end
