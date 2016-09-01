module Doorkeeper
  class AccessCleanup
    attr_reader :keep_for_days

    def initialize(keep_for_days: 30)
      @keep_for_days = keep_for_days
    end

    def cleanup!
      Doorkeeper::AccessGrant.transaction {
        expired_grants.delete_all
        expired_tokens.delete_all
      }
    end

    def expired_grants
      Doorkeeper::AccessGrant.where(expiry_params)
    end

    def expired_tokens
      Doorkeeper::AccessToken.where(expiry_params)
    end

    def delete_before
      DateTime.now - keep_for_days.days
    end

    protected

    def expiry_params
      ["created_at < ? OR revoked_at IS NOT NULL", delete_before]
    end
  end
end
