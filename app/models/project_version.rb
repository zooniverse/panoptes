class ProjectVersion < ActiveRecord::Base
  belongs_to :project

  def self.build_from(project)
    version = new
    version.project = project
    version.private = project.private
    version.live = project.live
    version.beta_requested = project.beta_requested
    version.beta_approved = project.beta_approved
    version.launch_requested = project.launch_requested
    version.launch_approved = project.launch_approved
    version.display_name = project.display_name
    version.description = project.description
    version.workflow_description = project.workflow_description
    version.introduction = project.introduction
    version.url_labels = project.url_labels
    version.researcher_quote = project.researcher_quote
    version
  end

  def self.create_from(project)
    version = build_from(project)
    version.save!
    version
  end
end
