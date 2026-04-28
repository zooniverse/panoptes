# frozen_string_literal: true

class CreateDoorkeeperOpenidConnectTables < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    safety_assured do
      # Schema defined by doorkeeper-openid_connect; timestamps not applicable.
      create_table :oauth_openid_requests do |t| # rubocop:disable Rails/CreateTableWithTimestamps
        t.references :access_grant, null: false, index: true
        t.string :nonce, null: false
      end

      add_foreign_key(
        :oauth_openid_requests,
        :oauth_access_grants,
        column: :access_grant_id,
        on_delete: :cascade
      )
    end
  end
end
