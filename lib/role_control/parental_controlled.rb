module RoleControl
  module ParentalControlled
    extend ActiveSupport::Concern
    include RoleControl::Controlled

    included do
      scope :private_scope, ->  {
        private_scope = parent_class.private_scope

        if Panoptes.flipper["test_no_join_parental_scope"].enabled?
          where(parent_foreign_key => private_scope.pluck(:id))
        else
          joins(@parent).merge(private_scope)
        end
      }
      scope :public_scope, -> {
        public_scope = parent_class.public_scope

        if Panoptes.flipper["test_no_join_parental_scope"].enabled?
          where(parent_foreign_key => public_scope.pluck(:id))
        else
          joins(@parent).merge(public_scope)
        end
      }
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

      def parent_foreign_key
        reflect_on_association(@parent).foreign_key
      end

      def scope_for(action, user, opts={})
        parent_scope = parent_class.scope_for(action, user, opts)

        if Panoptes.flipper["test_no_join_parental_scope"].enabled?
          where(parent_foreign_key => parent_scope.pluck(:id))
        else
          joins(@parent).merge(parent_scope)
        end
      end
    end
  end
end
