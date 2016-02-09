module Memberships
  class Create < Operation
    string :join_token, default: nil

    hash :links do
      integer :user
      integer :user_group
    end

    def execute
      raise Unauthenticated unless api_user.logged_in?
      raise Unauthorized unless user_group.verify_join_token(join_token)
      raise Unauthorized unless user.id == api_user.id

      Membership.create! user: api_user.user, user_group: user_group, state: :active
    end

    def user
      User.find(links["user"])
    end

    def user_group
      UserGroup.find(links["user_group"])
    end
  end
end
