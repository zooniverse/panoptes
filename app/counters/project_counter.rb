class ProjectCounter

  attr_reader :project

  def initialize(project)
    @project = project
  end

  def volunteers
    UserProjectPreference
      .where(project_id: project.id)
      .where.not(email_communication: nil)
      .count
  end

  def classifications
    project.workflows.where(active: true).sum(:classifications_count)
  end
end
