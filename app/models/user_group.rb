class UserGroup < ActiveRecord::Base
  include Nameable
  has_many :projects, as: :owner
  has_many :collections, as: :owner

  has_many :users, through: :memberships
  has_many :memberships

  def classifications_count
    users(true).map(&:classifications_count).inject(:+)
  end
end
