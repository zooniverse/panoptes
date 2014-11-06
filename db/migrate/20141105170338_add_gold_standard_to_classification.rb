class AddGoldStandardToClassification < ActiveRecord::Migration
  def change
    add_column :classifications, :gold_standard, :boolean
  end
end
