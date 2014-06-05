class UserGroup < ActiveRecord::Base
  include Nameable
  include Activatable
  include Owner

  owns :projects, :collections, :subjects

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

end
