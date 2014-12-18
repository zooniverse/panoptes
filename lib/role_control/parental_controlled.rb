module RoleControl
  module ParentalControlled
    extend ActiveSupport::Concern
    include RoleControl::Controlled

    module ClassMethods
      include RoleControl::Controlled::ClassMethods

      def can_through_parent(parent, *actions)
        @parent = parent
        @actions = actions
      end
      
      def scope_for(action, target, opts={})
        if @actions.include? action
          parent_scope = @parent.to_s.camelize.constantize
                         .scope_for(action, target)
          joins(@parent).where(@parent => parent_scope)
        end
      end
    end
  end
end
