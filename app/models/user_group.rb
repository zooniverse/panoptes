class UserGroup < ActiveRecord::Base
  has_many :users, through: :user_group_memberships
  has_many :user_group_memberships
end
