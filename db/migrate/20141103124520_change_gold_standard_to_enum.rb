class ChangeGoldStandardToEnum < ActiveRecord::Migration
  def self.up
    remove_column :classifications, :gold_standard
    add_column :classifications, :expert_classifier, :integer
  end

  def self.down
    remove_column :classifications, :expert_classifier
    add_column :classifications, :gold_standard, :boolean, default: false, null: false
  end
end
