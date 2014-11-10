class AddExpertClassifierEnum < ActiveRecord::Migration
  def change
    add_column :classifications, :expert_classifier, :integer
  end
end
