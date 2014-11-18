class UserCollectionPreference < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::Adminable
  include RoleControl::RoleModel
  include Preferences
  
  belongs_to :user, dependent: :destroy
  belongs_to :collection, dependent: :destroy

  roles_for :user, :collection, valid_roles: [ :collaborator ]
  
  validates_presence_of :user, :collection
  
  visibility_query UserCollectionPreferenceVisibilityQuery
end
