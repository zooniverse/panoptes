# frozen_string_literal: true

class AddConfigurationToTutorials < ActiveRecord::Migration
  def change
    safety_assured { add_column :tutorials, :configuration, :jsonb, default: {} }
  end
end
