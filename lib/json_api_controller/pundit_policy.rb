module JsonApiController
  module PunditPolicy
    extend ActiveSupport::Concern

    included do
      after_action :verify_policy_scoped, except: [:create]
    end

    def verify_policy_scoped
      raise Pundit::PolicyScopingNotPerformedError, self.class unless policy_scoped?
    end

    def policy
      @policy ||= Pundit.policy!(api_user, resource_class)
    end

    def policy_scope
      @_policy_scoped = true

      scope = policy.scope_for(action_name.to_sym)

      if resource_ids.present?
        scope = scope.where(id: resource_ids)
      end

      if add_active_scope && scope.respond_to?(:active)
        scope = scope.active
      end

      scope
    end

    def add_active_scope
      true
    end

    def skip_policy_scope
      @_policy_scoped = true
    end

    def policy_scoped?
      !!@_policy_scoped
    end
  end
end
