# frozen_string_literal: true

class AddConfirmableToDevise < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime

    add_index :users, :confirmation_token, unique: true, algorithm: :concurrently
  end

  def down
    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at

    remove_index :users, :confirmation_token
  end
end
