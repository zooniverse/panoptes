class AddDefaultsToProjectContent < ActiveRecord::Migration
  def change
    %i(title description introduction science_case result faq education_content).each do |column|
      change_column_default :project_contents, column, ""
    end
  end
end
