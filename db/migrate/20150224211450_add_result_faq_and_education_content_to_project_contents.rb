class AddResultFaqAndEducationContentToProjectContents < ActiveRecord::Migration
  def change
    add_column :project_contents, :faq, :string
    add_column :project_contents, :result, :string
    add_column :project_contents, :education_content, :string
  end
end
