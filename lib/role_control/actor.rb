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
        self
      end

      def with_ids(ids)
        @scope = scope.where(id: ids).order(:id) unless ids.blank?
        self
      end

      private

    end

    def do(action, &block)
      DoChain.new(self, action, &block)
    end
  end
end
