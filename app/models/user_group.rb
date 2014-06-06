class UserGroup < ActiveRecord::Base
  include Nameable
  include Activateable

  has_many :projects, as: :owner, extend: Activateable::ActivateProxyHasMany 
  has_many :collections, as: :owner, extend: Activateable::ActivateProxyHasMany 
  has_many :subjects, as: :owner

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

  proxy_status :projects, :collections
end
