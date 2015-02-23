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

      def joins_for
        { access_control_lists: { user_group: :memberships } }
      end

      def memberships_query(action, target)
        target.memberships_for(action, self)
      end

      def private_query(query, action, target, roles)
        query.merge(memberships_query(action, target))
          .where.overlap(access_control_lists: { roles: roles })
      end

      def public_query(query, public)
        if public
          query.merge(private_scope).union_all(public_scope)
        else
          query
        end
      end

      def scope_for(action, target, opts={})
        roles, public = roles(action)

        case
        when target.is_admin?
          all
        when target.logged_in?
          query = private_query(joins(joins_for), action, target, roles)
          public_query(query, public)
        when public_scope
          public_scope
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
