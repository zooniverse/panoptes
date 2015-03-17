module RoleControl
  module ParentalControlled
    extend ActiveSupport::Concern
    include RoleControl::Controlled

    included do
      scope :private_scope, -> { joins(@parent).merge(parent_class.private_scope) }
      scope :public_scope, -> { joins(@parent).merge(parent_class.public_scope) }
    end

    module ClassMethods
      include RoleControl::Controlled::ClassMethods

      def can_through_parent(parent, *actions)
        @parent = parent
        @actions = actions
      end

      def parent_class
        @parent_class ||= @parent.to_s.camelize.constantize
      end

      def scope_for(action, user, opts={})
        joins(@parent).merge(parent_class.scope_for(action, user, opts))
      end
    end
  end
end
