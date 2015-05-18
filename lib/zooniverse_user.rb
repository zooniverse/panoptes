class ZooniverseUser < ActiveRecord::Base
  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'users'

  attr_reader :password

  validates_uniqueness_of :email, :login, case_sensitive: false

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
    self.crypted_password = Sha1Encryption.encrypt(plain_password, password_salt)
  end

  def authenticate(plain_password)
    worked = nil
    1.upto(25).each do |n|
      if crypted_password == Sha1Encryption.encrypt(plain_password, password_salt, -n)
        worked = n
        break
      end
    end
    worked ? self : nil
  end

  def import
    #use the indexed field
    user = User.find_or_initialize_by(display_name: login)
    return nil if user.disabled?
    setup_panoptes_user_account(user)
    user.save ? user : nil
  end

  def set_tokens!
    self.persistence_token = hex_token
    self.single_access_token = simple_token
    self.perishable_token = simple_token
  end

  private

  def avatar_to_url
    if avatar_file_name
      "http://zooniverse-avatars.s3.amazonaws.com/users/#{ id }/forum#{ File.extname(avatar_file_name) }"
    else
      "http://zooniverse-avatars.s3.amazonaws.com/default_forum_avatar.png"
    end
  end

  def simple_token
    SecureRandom.base64(15).tr('+/=', '').strip.delete "\n"
  end

  def hex_token
    SecureRandom.hex 64
  end

  def setup_panoptes_user_account(pu)
    if new_account = !pu.persisted?
      pu.build_avatar(external_link: true, src: avatar_to_url)
      pu.build_identity_group
    end
    pu.display_name = login
    pu.email = email
    pu.encrypted_password = crypted_password
    pu.password_salt = password_salt
    pu.valid_email = valid_email || true
    pu.created_at = created_at
    pu.updated_at = updated_at
    pu.hash_func = 'sha1'
    pu.migrated = true
    pu.zooniverse_id = id.to_s
  end
end
