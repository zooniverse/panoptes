class AddGoldStandardSparseIndex < ActiveRecord::Migration
  def change
    add_index :classifications, :gold_standard, where: "gold_standard IS TRUE"
  end
end
