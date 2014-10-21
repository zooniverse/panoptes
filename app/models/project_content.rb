class ProjectContent < ActiveRecord::Base
  include TranslatedContent
  include RoleControl::ParentalControlled
  
  can_through_parent :project, :show
  
  can :update do |actor|
    (project.can_update?(actor) || is_project_translator?(actor)) &&
      !is_primary?
  end
  
  can :destroy do |actor|
    project.can_destroy?(actor) && !is_primary?
  end
  
  attr_accessible :language, :title, :description, :guide, :team_members,
    :science_case, :introduction
  validates_presence_of(:title, :description)

  def is_project_translator?(actor)
    project.is_translator?(actor)
  end

  def is_primary?
    language == project.primary_language
  end
end
