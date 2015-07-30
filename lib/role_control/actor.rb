module RoleControl
  module Actor
    class DoChain
      attr_reader :scope, :action, :actor

      def initialize(actor, action)
        @action = action
        @actor = actor
      end

      def to(klass, context={})
        @scope = klass.scope_for(action, actor, context)
        @scope = @scope.merge(klass.active) if klass.respond_to?(:active)
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
