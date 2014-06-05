class User < ActiveRecord::Base
  include Nameable
  include Owner
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :user_groups, through: :memberships
  has_many :memberships
  has_many :classifications

  owns :projects, :collections, :subjects, 
    [:oauth_applications, {class_name: "Doorkeeper::Application"}]

  validates :login, presence: true, uniqueness: true
  validates_length_of :password, within: 8..128, allow_blank: true, unless: :migrated_user?

  attr_accessor :migrated_user

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
