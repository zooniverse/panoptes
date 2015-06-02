class User < ActiveRecord::Base
  include Activatable
  include Linkable

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :omniauthable, omniauth_providers: [:facebook, :gplus]

  has_many :classifications
  has_many :authorizations, dependent: :destroy
  has_many :collection_preferences, class_name: "UserCollectionPreference", dependent: :destroy
  has_many :project_preferences, class_name: "UserProjectPreference", dependent: :destroy
  has_many :oauth_applications, class_name: "Doorkeeper::Application", as: :owner, dependent: :destroy

  has_many :memberships, dependent: :destroy
  has_many :active_memberships, -> { active }, class_name: 'Membership'
  has_one :identity_membership, -> { identity }, class_name: 'Membership'
  has_one :avatar, -> { where(type: "user_avatar")}, class_name: "Medium", as: :linked
  has_one :profile_header, -> { where(type: "user_profile_header")}, class_name: "Medium", as: :linked

  has_many :user_groups, through: :active_memberships
  has_one :identity_group, through: :identity_membership,
    source: :user_group, class_name: "UserGroup", dependent: :destroy

  has_many :project_roles, through: :identity_group
  has_many :collection_roles, through: :identity_group
  has_many :user_seen_subjects, dependent: :destroy
  has_many :uploaded_subjects, class_name: "Subject", foreign_key: "upload_user_id"

  has_many :subject_queues, dependent: :destroy

  belongs_to :signup_project, class_name: 'Project', foreign_key: "project_id"

  validates :display_name, presence: true, uniqueness: { case_sensitive: false },
    format: { without: /\$|@|\s+/ }, unless: :migrated
  validates_length_of :password, within: 8..128, allow_blank: true, unless: :migrated
  validates_inclusion_of :valid_email, in: [true, false], message: "must be true or false"

  validates_with IdentityGroupNameValidator

  delegate :projects, to: :identity_group
  delegate :collections, to: :identity_group
  delegate :subjects, to: :identity_group
  delegate :owns?, to: :identity_group

  can_be_linked :membership, :all
  can_be_linked :user_group, :all
  can_be_linked :subject_queue, :all
  can_be_linked :user_project_preference, :all
  can_be_linked :user_collection_preference, :all
  can_be_linked :project, :scope_for, :update, :user
  can_be_linked :collection, :scope_for, :update, :user

  def self.scope_for(action, user, opts={})
    case action
    when :show, :index
      active
    else
      where(id: user.id)
    end
  end

  def self.from_omniauth(auth_hash)
    auth = Authorization.from_omniauth(auth_hash)
    auth.user ||= create do |u|
      u.email = auth_hash.info.email
      u.password = Devise.friendly_token[0,20]
      name = auth_hash.info.name
      u.display_name = StringConverter.replace_spaces(name)
      u.build_identity_group
      u.authorizations << auth
    end
  end

  def self.reflect_on_association(association_name)
    case association_name.to_sym
    when :projects, :collections
      UserGroup.reflect_on_association(association_name)
    else
      super
    end
  end

  def self.find_for_database_authentication(conditions = {})
    where('lower("users"."display_name") = lower(?)', conditions[:display_name]).first || super
  end

  def memberships_for(action, klass)
    membership_roles = UserGroup.roles_allowed_to_access(action, klass)
    active_memberships.where.overlap(roles: membership_roles)
  end

  def password_required?
    super && hash_func != 'sha1'
  end

  def password=(new_password)
    super
    self.hash_func = 'bcrypt' if @password.present?
  end

  def valid_password?(password)
    case hash_func
    when 'bcrypt'
      super(password)
    when 'sha1'
      valid_sha1_password?(password)
    else
      false
    end
  end

  def active_for_authentication?
    !disabled? && super
  end

  def email_required?
    authorizations.blank? && !disabled?
  end

  def email_changed?
    authorizations.blank?
  end

  def build_identity_group
    raise StandardError, "Identity Group Exists" if identity_group
    build_identity_membership
    identity_membership.build_user_group(display_name: display_name)
  end

  def is_admin?
    !!admin
  end

  def has_finished?(workflow)
    seen_count = user_seen_subjects.where(workflow_id: workflow.id)
      .select('array_length("user_seen_subjects"."subject_ids", 1) as subject_count')
      .first.try(:subject_count)

    !!(seen_count && seen_count >= workflow.subjects_count)
  end

  def valid_sha1_password?(plain_password)
    worked = nil
    1.upto(25).each do |n|
      if encrypted_password == Sha1Encryption.encrypt(plain_password, password_salt, -n)
        worked = n
        logger.info "User #{id} is using sha1 password. Updating..."
        self.password = plain_password
        self.hash_func = 'bcrypt'
        self.save!
        break
      end
    end
    !!worked
  end
end
