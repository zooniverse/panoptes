class ZooniverseUser < ActiveRecord::Base
  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'users'

  attr_reader :password

  validates_uniqueness_of :email, :login

  def self.import_users(users=nil)
    if users.blank?
      self
    else
      where(login: users)
    end.find_each(&:import)
  end

  def self.authenticate(username, password)
    find_by(login: username).try(:authenticate, password)
  end

  def self.find_from_user(user)
    if user.zooniverse_id
      return find(user.zooniverse_id)
    end
  end

  def self.create_from_user(user)
    zu = create do |u|
      u.login = user.display_name
      u.name = user.display_name
      u.password = user.password
      u.email = user.email
      u.set_tokens!
    end
    user.zooniverse_id = zu.id.to_s
    zu
  end

  def password=(plain_password)
    return unless plain_password
    @password = plain_password
    self.password_salt = simple_token
    self.crypted_password = Sha1Encryption.encrypt(plain_password, salt: password_salt)
  end

  def authenticate(plain_password)
    crypted_password == Sha1Encryption.encrypt(plain_password, salt: password_salt) ? self : nil
  end

  def import
    #use the indexed field
    user = User.find_or_initialize_by(display_name: login)
    setup_panoptes_user_account(user)
    user.save ? user : nil
  end

  def set_tokens!
    self.persistence_token = hex_token
    self.single_access_token = simple_token
    self.perishable_token = simple_token
  end

  private

  def simple_token
    SecureRandom.base64(15).tr('+/=', '').strip.delete "\n"
  end

  def hex_token
    SecureRandom.hex 64
  end

  def setup_panoptes_user_account(u)
    panoptes_account_exists = panoptes_user_account_exists?(u)
    new_account = !u.persisted?
    u.display_name = login
    u.email = email
    u.encrypted_password = crypted_password
    u.password_salt = password_salt
    if new_account || panoptes_account_exists
      u.created_at = created_at
      u.updated_at = updated_at
      u.hash_func = 'sha1'
      u.migrated = true
      u.zooniverse_id = id.to_s
      u.build_identity_group if new_account
    end
  end

  def panoptes_user_account_exists?(user)
    user.display_name = login &&
    user.zooniverse_id.nil? &&
    user.hash_func == 'bcrypt' &&
    user.migrated.blank?
  end
end
