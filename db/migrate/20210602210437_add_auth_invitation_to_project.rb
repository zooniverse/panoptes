# frozen_string_literal: true

class AddAuthInvitationToProject < ActiveRecord::Migration
  def change
    # since PG v11+ we can add a new column and a default at the same time
    # as it no longer requires a table rewrite 
    # https://github.com/ankane/strong_migrations#bad-1
    # https://www.2ndquadrant.com/en/blog/add-new-table-column-default-value-postgresql-11/
    add_column :projects, :authentication_invitation, :text, default: ''
  end
end
