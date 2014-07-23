class CreateWorkflowContents < ActiveRecord::Migration
  def change
    create_table :workflow_contents do |t|
      t.references :workflow, index: true
      t.string :language
      t.json :strings

      t.timestamps
    end
  end
end
