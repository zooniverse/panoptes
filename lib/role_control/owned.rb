module RoleControl
  module Owned
    extend ActiveSupport::Concern

    included do
      has_many :access_control_lists, as: :resource, dependent: :destroy
      has_one :owner_control_list, -> { where.overlap(roles: ["owner"]) }, as: :resource, class_name: "AccessControlList"
      has_one :owner, through: :owner_control_list, source: :user_group, as: :resource, class_name: "UserGroup"

      scope :public_scope, -> { where(private: false) }

      validates_presence_of :owner

      include OwnerOverrides
    end

    module OwnerOverrides
      def owner=(o)
        owning_group = case o
                       when ApiUser
                         o.user.identity_group
                       when User
                         o.identity_group
                       when UserGroup
                         o
                       end
        build_owner_control_list(user_group: owning_group, roles: ["owner"])
        super(owning_group)
      end

      def owner(reload=nil)
        group = super(reload)
        if group.try(:identity?)
          group.users.first
        else
          group
        end
      end

      def owner?(test_owner)
        owner == test_owner
      end
    end
  end
end
