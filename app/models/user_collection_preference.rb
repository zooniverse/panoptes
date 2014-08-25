class UserCollectionPreference < ActiveRecord::Base
  include RoleControl::RoleModel
  belongs_to :user
  belongs_to :collection
  
  roles_for :user, :collection, valid_roles: [ :collaborator ]
  
  validates_presence_of :user, :collection
end
