class Collection < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Owned
  include Activatable
  include Linkable
  include PreferencesLink
  
  belongs_to :project
  has_and_belongs_to_many :subjects
  
  ## TODO: Figure out how to do these validations
  #validates_uniqueness_of :name, case_sensitive: false, scope: :owner
  #validates_uniqueness_of :display_name, scope: :owner

  can_by_role :destroy, :update, :update_links, :destroy_links,
              roles: [ :owner, :collaborator ]
  can_by_role :index, :show, public: :public_scope,
              roles: [ :owner, :collaborator, :viewer ]
  
  preferences_model :user_collection_preference
end
