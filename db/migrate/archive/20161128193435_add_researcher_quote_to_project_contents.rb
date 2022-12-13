class AddResearcherQuoteToProjectContents < ActiveRecord::Migration
  def change
    add_column :project_contents, :researcher_quote, :text, default: ""
  end
end
