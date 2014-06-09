class UserGroup < ActiveRecord::Base
  include Nameable
  include Activatable

  has_many :projects, as: :owner
  has_many :collections, as: :owner
  has_many :subjects, as: :owner

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

end
