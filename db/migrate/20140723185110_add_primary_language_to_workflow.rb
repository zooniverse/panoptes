class AddPrimaryLanguageToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :primary_language, :string
  end
end
