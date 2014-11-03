class AddGoldStandardToClassification < ActiveRecord::Migration
  def change
    add_column :classifications, :gold_standard, :boolean, default: false, null: false
  end
end
