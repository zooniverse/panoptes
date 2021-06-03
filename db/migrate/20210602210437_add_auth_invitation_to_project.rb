class AddAuthInvitationToProject < ActiveRecord::Migration
  def change
    add_column :projects, :authentication_invitation, :string
  end
end
