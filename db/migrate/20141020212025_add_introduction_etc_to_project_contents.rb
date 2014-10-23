class AddIntroductionEtcToProjectContents < ActiveRecord::Migration
  def change
    add_column :project_contents, :introduction, :text
    add_column :project_contents, :science_case, :text
    add_column :project_contents, :team_members, :json
    add_column :project_contents, :guide, :json
  end
end
