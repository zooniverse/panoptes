module RoleControl
  module Controlled
    extend ActiveSupport::Concern

    included do
      @roles_for = Hash.new
      @public = Hash.new
    end

    module ClassMethods
      def can_by_role(action,
                      roles: [],
                      public: nil,
                      role_association: :access_control_lists)
        
        @roles_for[action] = [roles,
                              role_association,
                              public]
      end

      def scope_for(action, target)
        roles, assoc, public_scope = roles(action)
        target_name = target.class.name.underscore
        assoc_table = reflect_on_association(assoc).table_name
        
        query = joins(assoc)
          .where(assoc_table => { target_name => target })
          .where.overlap(assoc_table => { roles: roles })
        
        public_scope ? query.union(send(public_scope)) : query
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
