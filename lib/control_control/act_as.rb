module ControlControl
  module ActAs
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def may_act_on(target_class, actor_in: actor_scope, target_in: target_scope, action: action)
        @actor_rules ||= Hash.new
        @actor_rules[target_class] ||= Hash.new
        actor_scope = self.send(actor_scope) if actor_scope.is_a?(Symbol)
        target_scope = self.send(actor_scope) if target_scope.is_a?(Symbol)
        @actor_rules[target_class][action] = [actor_scope, target_scope]
      end

      def allowed_to_act?(actor, target, action)
        actor_scope, target_scope = @actor_rules[target.class][action]
        (actor_scope.nil? || actor_scope.exists?(actor)) &&
          (target_scope.nil? || target_scope.exists?(target))
      end
    end

    def can_act_on_as?(target, actor, action)
      self.class.allowed_to_act?(actor, target, action)
    end
  end
end
