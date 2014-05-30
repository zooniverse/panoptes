class UserGroup < ActiveRecord::Base
  include Nameable
  has_many :projects, as: :owner
  has_many :collections, as: :owner

  has_many :users, through: :memberships
  has_many :memberships
end
