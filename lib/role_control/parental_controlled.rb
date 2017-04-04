module RoleControl
  module ParentalControlled
    extend ActiveSupport::Concern
    include RoleControl::Controlled

    included do
      scope :private_scope, -> { parent_scope(parent_class.private_scope) }
      scope :public_scope,  -> { parent_scope(parent_class.public_scope) }
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

      def parent_relation
       @parent
     end

      def parent_foreign_key
        reflect_on_association(@parent).foreign_key
      end

      def parent_scope(scope)
        where(parent_foreign_key => scope.select(:id))
      end

      def scope_for(action, user, opts={})
        parent_scope(parent_class.scope_for(action, user, opts))
      end
    end
  end
end
