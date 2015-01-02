module RoleControl
  module Actor
    class DoChain
      attr_reader :scope, :action, :actor, :block
      
      def initialize(actor, action, &block)
        @action = action
        @actor = actor
        @block = block
      end
      
      def to(klass, context={})
        actors = block.call(actor, action, klass, context)
        @scope = klass.scope_for(action, actors, context)
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
