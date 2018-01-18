class Collection < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Owned
  include Activatable
  include Linkable
  include PreferencesLink
  include PgSearch
  include SluggedName

  has_and_belongs_to_many :projects
  has_many :collections_subjects, dependent: :destroy
  has_many :subjects, through: :collections_subjects
  has_many :collection_roles, -> { where.not(roles: []) }, class_name: "AccessControlList", as: :resource
  has_many :user_collection_preferences, dependent: :destroy
  belongs_to :default_subject, :class_name => "Subject"

  validates :display_name, presence: true
  validates :private, inclusion: { in: [true, false], message: "can't be blank" }
  ## TODO: This potential has locking issues
  validates_with UniqueForOwnerValidator

  can_by_role :destroy, :update, :destroy_links, roles: [ :owner, :collaborator ]
  can_by_role :update_links, roles: [ :owner, :collaborator, :contributor ]
  can_by_role :index, :show, public: true, roles: [ :owner, :collaborator, :viewer, :contributor ]

  can_be_linked :access_control_list, :scope_for, :update, :user

  preferences_model :user_collection_preference

  pg_search_scope :search_display_name,
    against: :display_name,
    using: :trigram,
    ranked_by: ":trigram"
end
