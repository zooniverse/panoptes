module RoleControl
  module Actor
    class DoChain
      attr_reader :scope, :action, :actor

      def initialize(actor, action)
        @action = action
        @actor = actor
      end

      def to(klass, context={}, add_active_scope: true)
        @scope = klass.scope_for(action, actor, context)
        if add_active_scope && klass.respond_to?(:active)
          @scope = @scope.merge(klass.active)
        end
        self
      end

      def with_ids(ids)
        @scope = scope.where(id: ids).order(:id) unless ids.blank?
        self
      end
    end

    def do(action, &block)
      DoChain.new(self, action, &block)
    end
  end
end
