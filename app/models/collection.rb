class Collection < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Owned
  include Activatable
  include Linkable
  include PreferencesLink

  belongs_to :project
  has_many :collections_subjects, dependent: :destroy
  has_many :subjects, through: :collections_subjects

  ## TODO: This potential has locking issues
  validates_with UniqueForOwnerValidator

  can_by_role :destroy, :update, :update_links, :destroy_links,
              roles: [ :owner, :collaborator ]
  can_by_role :index, :show, public: true, roles: [ :owner, :collaborator, :viewer ]

  preferences_model :user_collection_preference
end
