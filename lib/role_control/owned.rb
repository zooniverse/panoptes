module RoleControl
  module Owned
    extend ActiveSupport::Concern

    included do
      has_many :access_control_lists, as: :resource, dependent: :destroy
      has_one :owner_control_list, -> { where("roles && '{owner}'") }, as: :resource, class_name: "AccessControlList"
      has_one :owner, through: :owner_control_list, source: :user_group, as: :resource, class_name: "UserGroup"

      scope :public_scope, -> { where(private: false) }

      validates_presence_of :owner

      def self.filter_by_owner(owner_groups)
        eager_load(owner: { identity_membership: :user })
        .joins(:owner)
        .where(access_control_lists: { user_group: owner_groups })
      end

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

      # NOTE: this owner data model adds complexity and fights the framework
      # when trying to load data via relations...we should seriously consider
      # how to remove this and simplify the owner relations (resource -> owner [:user]?)
      #
      # this method returns either the identity user or the owning group.
      # It was setup this way to allow groups and users to own resources via IdentityGroups
      def owner
        owner_group = super
        # trying to pre/eager load on relations other than owner does not work
        # when using this relation accessor override
        # ...and that makes me sad, it does work if you remove this owner override
        # but you lose the ability to return the correct owner resource...
        if owner_group&.identity?
          # ensure that this chained call matches the pre/eager loading setup
          owner_group.identity_membership.user
        else
          owner_group
        end
      end

      def owner?(test_owner)
        owner == test_owner
      end
    end
  end
end
