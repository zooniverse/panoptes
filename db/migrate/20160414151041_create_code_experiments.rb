class CreateCodeExperiments < ActiveRecord::Migration
  def change
    create_table :code_experiment_configs do |t|
      t.string :name, null: false
      t.float :enabled_rate, null: false, default: 0
      t.boolean :always_enabled_for_admins, null: false, default: true
    end

    add_index :code_experiment_configs, :name, unique: true
  end
end
