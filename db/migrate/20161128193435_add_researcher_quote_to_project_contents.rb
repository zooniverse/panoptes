class AddResearcherQuoteToProjectContents < ActiveRecord::Migration
  def change
    add_column :project_contents, :researcher_quote, :text

    add_index :project_contents, :researcher_quote
  end
end
