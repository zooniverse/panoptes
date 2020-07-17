class AddConfigurationToTutorials < ActiveRecord::Migration
  def change
    add_column :tutorials, :configuration, :jsonb
  end
end
