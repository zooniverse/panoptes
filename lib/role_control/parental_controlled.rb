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

      def parent_table
        parent_class.table_name
      end

      def parent_class
        @parent_class ||= @parent.to_s.camelize.constantize
      end

      def roles(action)
        parent_class.roles(action)
      end

      def joins_for
        {@parent => parent_class.joins_for}
      end

      def memberships_query(action, target)
        target.memberships_for(action, parent_class)
      end
    end
  end
end
