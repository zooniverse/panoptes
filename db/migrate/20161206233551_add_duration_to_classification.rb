class AddDurationToClassification < ActiveRecord::Migration
  def change
    add_column :classifications, :duration, :integer
  end
end
