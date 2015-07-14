class Collection < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Owned
  include Activatable
  include Linkable
  include PreferencesLink
  include PgSearch

  acts_as_url :display_name, sync_url: true, url_attribute: :slug, allow_duplicates: true

  belongs_to :project
  has_many :collections_subjects, dependent: :destroy
  has_many :subjects, through: :collections_subjects
  has_many :collection_roles, -> { where.not(roles: []) }, class_name: "AccessControlList", as: :resource

  validates :display_name, presence: true
  ## TODO: This potential has locking issues
  validates_with UniqueForOwnerValidator

  can_by_role :destroy, :update, :update_links, :destroy_links,
              roles: [ :owner, :collaborator ]
  can_by_role :index, :show, public: true, roles: [ :owner, :collaborator, :viewer ]

  can_be_linked :access_control_list, :scope_for, :update, :user

  preferences_model :user_collection_preference

  pg_search_scope :search_display_name,
    against: :display_name,
    using: :trigram,
    ranked_by: ":trigram"
end
