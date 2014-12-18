module RoleControl
  module Controlled
    extend ActiveSupport::Concern

    included do
      @roles_for = Hash.new
      @public = Hash.new
    end

    module ClassMethods
      def can_by_role(*actions,
                      roles: [],
                      public: nil,
                      role_association: :access_control_lists)

        actions.each do |action|
          @roles_for[action] = [roles,
                                role_association,
                                public]
        end
      end

      def scope_for(action, target, opts={})
        roles, assoc, public_scope = roles(action)

        if target
          target_class = target.try(:klass) || target.class
          target_name = target_class.name.underscore
          assoc_table = reflect_on_association(assoc).table_name
        
          query = joins(assoc)
                  .where(assoc_table => { target_name => target })
                  .where.overlap(assoc_table => { roles: roles })

          public_scope ? query.union(send(public_scope)) : query
        elsif public_scope
          send(public_scope)
        else
          none
        end
      end

      def roles(action)
        @roles_for[action]
      end

      protected

      def role_test_proc(action)
        proc do |enrolled|
          self.class.scope_for(action, enrolled, target: self).exists?(self)
        end
      end
    end
  end
end
