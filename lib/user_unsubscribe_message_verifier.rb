module UserUnsubscribeMessageVerifier

  def self.verifier
    @verifier ||= Rails.application.message_verifier(:unsubscribe_token)
  end

  def self.create_access_token(value)
    verifier.generate(value)
  end

  def self.verify(signature)
    verifier.verify(signature)
  end
end
