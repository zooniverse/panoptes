module Memberships
  class Create < Operation
    string :join_token, default: nil

    hash :links do
      integer :user
      integer :user_group
    end

    def execute
      raise Unauthenticated unless api_user.logged_in?

      if join_token.blank?
        add_someone_else_to_a_group_you_admin
      else
        join_a_group
      end
    end

    def add_someone_else_to_a_group_you_admin
      raise Unauthorized unless user_group.public? || user_group.member?(api_user)
      Membership.create! user: user, user_group: user_group
    end

    def join_a_group
      raise Unauthorized unless user_group.verify_join_token(join_token)
      raise Unauthorized unless user.id == api_user.id
      Membership.create! user: user, user_group: user_group
    end

    def user
      User.find(links["user"])
    end

    def user_group
      UserGroup.find(links["user_group"])
    end
  end
end
