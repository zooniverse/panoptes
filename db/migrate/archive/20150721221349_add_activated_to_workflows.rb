class AddActivatedToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :active, :boolean, default: true, index: { where: "(active = true)" }
  end
end
