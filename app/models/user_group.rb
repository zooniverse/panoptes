class UserGroup < ActiveRecord::Base
  include Nameable
  include Activatable
  include Owner

  attr_accessible :display_name

  owns :projects, :collections, :subjects

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

  validates :display_name, presence: true, uniqueness: true
end
