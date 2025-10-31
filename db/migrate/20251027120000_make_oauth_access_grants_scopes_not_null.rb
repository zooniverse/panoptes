# frozen_string_literal: true

class MakeOauthAccessGrantsScopesNotNull < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      execute "UPDATE oauth_access_grants SET scopes = '' WHERE scopes IS NULL;"
    end

    change_column_default :oauth_access_grants, :scopes, ''

    safety_assured do
      execute <<-SQL.squish
        ALTER TABLE oauth_access_grants
        ADD CONSTRAINT check_oauth_access_grants_scopes_not_null
        CHECK (scopes IS NOT NULL) NOT VALID;
      SQL

      execute <<-SQL.squish
        ALTER TABLE oauth_access_grants
        VALIDATE CONSTRAINT check_oauth_access_grants_scopes_not_null;
      SQL
    end
  end

  def down
    execute "ALTER TABLE oauth_access_grants DROP CONSTRAINT check_oauth_access_grants_scopes_not_null;"
    change_column_default :oauth_access_grants, :scopes, nil
  end
end
