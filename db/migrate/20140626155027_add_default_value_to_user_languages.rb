class AddDefaultValueToUserLanguages < ActiveRecord::Migration

  def self.up
    change_column :users, :languages, :string, array: true, default: '{}', null: false
  end

  def self.down
    change_column :users, :languages, :string, array: true, default: nil, null: true
  end
end
