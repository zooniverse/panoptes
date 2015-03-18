class ProjectContentsText < ActiveRecord::Migration
  def up
    change_column :project_contents, :faq, :text
    change_column :project_contents, :result, :text
    change_column :project_contents, :education_content, :text
  end
  def down
      # this will chop strings that are longer than 255
      change_column :project_contents, :faq, :string
      change_column :project_contents, :result, :string
      change_column :project_contents, :education_content, :string
  end
end
