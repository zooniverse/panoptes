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
    classifications = project.classifications
    if launch_date
      classifications = classifications.where("created_at >= ?", launch_date)
    end
    classifications.count
  end

  def launch_date
    @launch_date ||= project.launch_date
  end
end
