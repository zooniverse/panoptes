module RoleControl
  module ParentalControlled
    extend ActiveSupport::Concern
    include RoleControl::Controlled

    module ClassMethods
      include RoleControl::Controlled::ClassMethods

      def can_through_parent(parent, *actions)
        @parent = parent
        @actions = actions
        
        actions.each do |action|
          method = "can_#{ action }?"
          define_method method do |*args|
            send(parent).send(method, *args)
          end
        end
      end
      
      def scope_for(action, *args)
        if @actions.include?(action)
          parent_scope = @parent.to_s.camelize.constantize
            .scope_for(action, *args)
          where(:"#{ @parent }_id" => parent_scope.select(:id))
        end
      end
    end
  end
end
