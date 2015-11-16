class AddPublicGoldStandardToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :public_gold_standard, :boolean, default: false
    add_index :workflows, :public_gold_standard, where: "public_gold_standard IS TRUE"
  end
end
