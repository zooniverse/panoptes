class Collection < ActiveRecord::Base
  include RoleControl::Owned
  include Activatable
  include PgSearch
  include SluggedName

  has_and_belongs_to_many :projects
  has_many :collections_subjects,
    -> { order(id: :desc) },
    dependent: :destroy
  has_many :subjects, through: :collections_subjects
  has_many :collection_roles, -> { where.not("access_control_lists.roles = '{}'") }, class_name: "AccessControlList", as: :resource
  has_many :user_collection_preferences, dependent: :destroy
  belongs_to :default_subject, :class_name => "Subject"

  validates :display_name, presence: true
  validates :private, inclusion: { in: [true, false], message: "can't be blank" }
  ## TODO: This potential has locking issues
  validates_with UniqueForOwnerValidator

  pg_search_scope :search_display_name,
    against: :display_name,
    using: :trigram,
    ranked_by: ":trigram"
end
