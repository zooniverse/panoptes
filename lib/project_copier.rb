class ProjectCopier
  EXCLUDE_ATTRIBUTES = [ :classifications_count, :launched_row_order, :beta_row_order ]
  INCLUDE_ATTRIBUTES = [  :project_contents,
                          :tutorials,
                          :field_guides,
                          :pages,
                          :tags,
                          :tagged_resources,
                          :avatar,
                          :background,
                          { active_workflows: [ :tutorials, :attached_images, :workflow_contents ] }
                        ]

  def self.copy(project_id, user_id)
    project = Project.find(project_id)
    user = User.find(user_id)

    copied_project = project.deep_clone include: INCLUDE_ATTRIBUTES, except: EXCLUDE_ATTRIBUTES
    copied_project.owner = user
    copied_project.save!
    copied_project
  end
end