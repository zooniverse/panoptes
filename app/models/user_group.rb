class UserGroup < ActiveRecord::Base
  include Nameable

  has_many :users, through: :memberships
  has_many :memberships
end
