class Collection < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Adminable
  include Activatable
  include Linkable
  include PreferencesLink
  
  belongs_to :project
  has_and_belongs_to_many :subjects
  
  has_one :owner_control_list, -> { where(role: "owner") }, as: :resource, class_name: "AccessControlList"
  has_one :owner, through: :owner_control_list, source: :user_group, as: :resource, class_name: "UserGroup"

  ## TODO: Figure out how to do these validations
  #validates_uniqueness_of :name, case_sensitive: false, scope: :owner
  #validates_uniqueness_of :display_name, scope: :owner

  can_by_role :update, roles: [ :collaborator ]
  can_by_role :show, public: true, roles: :visible_to
  
  preferences_model :user_collection_preference
end
