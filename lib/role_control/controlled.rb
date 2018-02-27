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
        user_group_memberships = memberships_query(action, target)
          .select(:user_group_id)
        AccessControlList
          .where(user_group_id: user_group_memberships)
          .where(resource_type: model_name.name)
          .select(:resource_id)
          .where("roles && ARRAY[?]::varchar[]", roles)
      end

      def user_can_access_scope(private_query, public_flag)
        scope = where(id: private_query.select(:resource_id))
        scope = scope.or(public_scope) if public_flag
        scope
      end

      def scope_for(action, user, opts={})
        roles, public_flag = roles(action)

        case
        when user.is_admin?
          all
        when user.logged_in?
          user_can_access_scope(
            private_query(action, user, roles),
            public_flag
          )
        when public_flag
          public_scope
        else
          none
        end
      end

      def roles(action)
        @roles_for[action]
      end
    end
  end
end
