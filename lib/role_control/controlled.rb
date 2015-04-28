module RoleControl
  module Controlled
    extend ActiveSupport::Concern

    included do
      @roles_for = Hash.new

      scope :public_scope, -> { where(private: false) }
      scope :private_scope, -> { where(private: true) }
    end

    module ClassMethods
      def can_by_role(*actions,
                      roles: [],
                      public: false)

        actions.each do |action|
          @roles_for[action] = [roles,
                                public]
        end
      end

      def memberships_query(action, target)
        target.memberships_for(action, self)
      end

      def private_query(action, target, roles)
        AccessControlList.joins(user_group: :memberships)
          .select(:resource_id)
          .merge(memberships_query(action, target))
          .where(resource_type: name)
          .where.overlap(roles: roles)
      end

      def public_query(private_query, public_flag)
        query = where(id: private_query)
        query = query.or(public_scope) if public_flag
        query
      end

      def scope_for(action, user, opts={})
        roles, public_flag = roles(action)

        case
        when user.is_admin?
          all
        when user.logged_in?
          public_query(private_query(action, user, roles), public_flag)
        when public_scope
          public_flag ? public_scope : none
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
