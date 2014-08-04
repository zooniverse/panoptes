module ControlControl
  module Actor
    class Action
      attr_reader :resource, :actor

      def initialize(action_name, actor) 
        @action = action_name
        @actor = actor
      end

      def to(resource)
        error unless resource.send(question, actor)
        @resource = resource
        self
      end

      def as(resource)
        return self if resource.nil?
        error unless resource.send(as_question, target, actor)
        @actor = resource
        self
      end

      def call(&block)
        block.call(actor, resource)
      end

      def allowed?
        true
      end

      private

      def question
        "can_#{ @action }?".to_sym
      end

      def as_question
        "can_#{ @action }_as?".to_sym
      end

      def error
        raise AccessDenied.new("Insufficient permissions to access resource")
      end
    end

    def do(action)
      Action.new(action, self)
    end
  end
end
