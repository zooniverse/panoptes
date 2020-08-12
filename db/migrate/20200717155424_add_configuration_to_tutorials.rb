# frozen_string_literal: true

class AddConfigurationToTutorials < ActiveRecord::Migration
  def change
    add_column :tutorials, :configuration, :jsonb
  end
end
