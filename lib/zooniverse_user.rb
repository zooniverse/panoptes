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
    user = User.find_or_initialize_by(zooniverse_id: id.to_s) do |u|
      u.display_name = login
      u.created_at = created_at
      u.updated_at = updated_at
      u.hash_func = 'sha1'
      u.migrated = true
      u.zooniverse_id = id.to_s
      u.build_identity_group
    end
    
    user.display_name = login
    user.email = email
    user.encrypted_password = crypted_password
    user.password_salt = password_salt
    
    user.save!
    user
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
end
