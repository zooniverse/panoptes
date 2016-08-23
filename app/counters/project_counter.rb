class ProjectCounter

  attr_reader :project

  def initialize(project)
    @project = project
  end

  def volunteers
    upps = UserProjectPreference
      .joins("INNER JOIN classifications ON classifications.user_id = user_project_preferences.user_id")
      .where(project_id: project.id)
    if launch_date
      upps = upps.where("user_project_preferences.created_at >= ?", launch_date)
    end
    upps.count
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
