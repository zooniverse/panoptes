module Doorkeeper
  class AccessCleanup
    def cleanup!(keep_old_refresh_tokens_for=14)
      remove_expired_grants
      remove_revoked_grants
      remove_expired_tokens
      remove_revoked_tokens
      remove_old_unused_refreshable_tokens
    end

    def remove_expired_grants
      Doorkeeper::AccessGrant.where(expired_clause).in_batches do |group|
        group.delete_all
      end
    end

    def remove_revoked_grants
      Doorkeeper::AccessGrant.where(revoked_clause).in_batches do |group|
        group.delete_all
      end
    end

    def remove_expired_tokens
      Doorkeeper::AccessToken.where(refresh_token: nil).where(expired_clause).in_batches do |group|
        group.delete_all
      end
    end

    def remove_revoked_tokens
      Doorkeeper::AccessToken.where(revoked_clause).in_batches do |group|
        group.delete_all
      end
    end

    def remove_old_unused_refreshable_tokens(keep_for)
      Doorkeeper::AccessToken
      .where.not(refresh_token: nil)
      .where(previous_refresh_token: nil)
      .where("created_at < ?", Time.now - keep_for.days)
      .in_batches do |group|
        group.delete_all
      end
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
