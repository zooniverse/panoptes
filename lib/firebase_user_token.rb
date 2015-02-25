require "firebase_token_generator"

class FirebaseUserToken

  def self.generate(user)
    return if user.nil? || FirebaseConfig.token.nil?
    payload = { uid: user.id.to_s }
    options = user.admin? ? { admin: true } : {}
    generator = Firebase::FirebaseTokenGenerator.new(FirebaseConfig.token)
    token = generator.create_token(payload, options)
  end
end
