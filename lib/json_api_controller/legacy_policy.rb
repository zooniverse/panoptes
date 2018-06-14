module JsonApiController
  module LegacyPolicy
    extend ActiveSupport::Concern

    def policy
      @policy ||= RoledControllerPolicy.new(api_user, resource_class, resource_ids, **policy_options)
    end

    def policy_scope
      @policy_scope ||= policy.scope_for(action_name.to_sym)
    end

    def policy_options
      {}
    end
  end
end
