class ProjectContent < ActiveRecord::Base
  include TranslatedContent
 
  attr_accessible :language, :title, :description, :guide, :team_members,
    :science_case, :introduction
  validates_presence_of :title, :description, :language
end
