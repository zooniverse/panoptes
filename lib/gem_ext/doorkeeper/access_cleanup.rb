module Doorkeeper
  class AccessCleanup
    def cleanup!(keep_old_refresh_tokens_for=14)
      expired_grants.delete_all
      revoked_grants.delete_all
      expired_tokens.delete_all
      revoked_tokens.delete_all
      old_unused_refreshable_tokens(keep_old_refresh_tokens_for).delete_all
    end

    def expired_grants
      Doorkeeper::AccessGrant.where(expired_clause)
    end

    def revoked_grants
      Doorkeeper::AccessGrant.where(revoked_clause)
    end

    def expired_tokens
      Doorkeeper::AccessToken.where(refresh_token: nil).where(expired_clause)
    end

    def revoked_tokens
      Doorkeeper::AccessToken.where(revoked_clause)
    end

    def old_unused_refreshable_tokens(keep_for)
      Doorkeeper::AccessToken
      .where.not(refresh_token: nil)
      .where(previous_refresh_token: nil)
      .where("created_at < ?", Time.now - keep_for.days)
    end

    private

    def revoked_clause
      "revoked_at IS NOT NULL"
    end

    def expired_clause
      "created_at + interval '1 second' * expires_in < clock_timestamp()"
    end
  end
end
