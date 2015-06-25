class AddIndexToOuroborosCreated < ActiveRecord::Migration
  def change
    add_index :users, :ouroboros_created, where: "ouroboros_created IS FALSE"
  end
end
