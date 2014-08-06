class User < ActiveRecord::Base
  extend ControlControl::Resource
  include Nameable
  include Activatable
  include ControlControl::Owner
  include RoleControl::Enrolled

  attr_accessible :name, :email, :password, :login, :migrated_user, :display_name, :credited_name, :global_email_communication,
    :project_email_communication

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:facebook, :gplus]

  has_many :user_groups, through: :memberships
  has_many :classifications
  has_many :authorizations
  has_many :user_project_preferences
  has_many :user_collection_preferences

  has_many :memberships
  has_many :active_memberships, -> { active }, class_name: 'Membership'
  
  owns :projects
  owns :collections
  owns :subjects
  owns :oauth_applications, class_name: "Doorkeeper::Application"

  roles_for Project, :user_project_preferences
  roles_for Collection, :user_collection_preferences
  roles_for UserGroup, :active_memberships

  validates :login, presence: true, uniqueness: true
  validates_length_of :password, within: 8..128, allow_blank: true, unless: :migrated_user?

  can :show, proc { |requester| requester == self }
  can :update, proc { |requester| requester == self }
  can :destroy, proc { |requester| requester == self }

  attr_accessor :migrated_user

  def self.from_omniauth(auth_hash)
    auth = Authorization.from_omniauth(auth_hash)
    auth.user ||= create do |u|
      u.email = auth_hash.info.email
      u.password = Devise.friendly_token[0,20]
      name = auth_hash.info.name
      u.display_name = name
      u.login = StringConverter.downcase_and_replace_spaces(name)
      u.owner_name = OwnerName.new(name: u.login, resource: u)
      u.authorizations << auth
    end
  end

  def password_required?
    super && hash_func != 'sha1'
  end

  def valid_password?(password)
    if hash_func == 'bcrypt'
      super(password)
    elsif hash_func == 'sha1'
      if encrypted_password = sha1_encrypt(password)
        logger.info "User #{id} is using sha1 password. Updating..."
        self.password = password
        self.hash_func = 'bcrypt'
        self.save
        true
      else
        false
      end
    else
      false
    end
  end

  def active_for_authentication?
    !disabled? && super
  end

  def email_required?
    authorizations.blank?
  end

  def email_changed?
    authorizations.blank?
  end

  def logged_in?
    true
  end

  protected

  def migrated_user?
    !!migrated_user
  end

  def sha1_encrypt(plain_password)
    bytes = plain_password.each_char.inject(''){ |bytes, c| bytes + c + "\x00" }
    concat = Base64.decode64(password_salt).force_encoding('utf-8') + bytes
    sha1 = Digest::SHA1.digest concat
    Base64.encode64(sha1).strip
  end
end
