class User < ActiveRecord::Base
  include Activatable
  include Owner

  attr_accessible :login, :email, :password, :migrated_user, :display_name, :credited_name
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:facebook]

  rolify

  has_many :user_groups, through: :memberships
  has_many :classifications
  has_many :memberships

  owns :projects, :collections, :subjects,
    [:oauth_applications, {class_name: "Doorkeeper::Application"}]

  validate :login, presence: true
  validate :unique_login
  validates_length_of :password, within: 8..128, allow_blank: true, unless: :migrated_user?

  attr_accessor :migrated_user

  def self.from_omniauth(auth_hash)
    where(auth_hash.slice(:provider, :uid)).first_or_create do |u|
      u.email = auth_hash.info.email
      u.password = Devise.friendly_token[0,20]
      u.display_name = auth_hash.info.name
      u.login = auth_hash.info.name.downcase.gsub(/\s/, '_')
      u.name = auth_hash.info.name.downcase.gsub(/\s/, '_')
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
    provider.nil?
  end

  def email_changed?
    provider.nil?
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

  private

  def unique_login
    unless UniqueRoutableName.new(self).unique?
      errors.add(:login, "is already taken")
    end
  end
end
