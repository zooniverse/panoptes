module ControlControl
  module Actor
    class Action
      attr_reader :target, :actor

      def initialize(action_name, actor) 
        @action = action_name
        @actor = actor
      end

      def to(resource)
        error unless resource.send(question, actor)
        @target = resource
        self
      end

      def as(resource, allow_nil: true)
        return self if !allow_nil && resource.nil?
        error unless resource.send(as_question, actor, target)
        @actor = resource
        self
      end

      def call(no_args: false, &block)
        unless no_args
          block.call(actor, target)
        else
          block.call
        end
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
