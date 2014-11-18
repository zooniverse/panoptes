class Authorization < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :provider, :uid, :token
  validates_uniqueness_of :provider, scope: :user_id

  def self.from_omniauth(auth_hash)
    hash = auth_hash.slice(:provider, :uid).to_hash.symbolize_keys
    auth = where(hash).first_or_create do |a|
      a.token = auth_hash.credentials.token
      a.expires_at = Time.at(auth_hash.credentials.expires_at).utc
    end

    if auth.persisted? && (auth.token != auth_hash.credentials.token)
      auth.token = auth_hash.credentials.token
      auth.expires_at = Time.at(auth_hash.credentials.expires_at).utc
      auth.save!
    end

    auth
  end
end
