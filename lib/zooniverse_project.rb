class ZooniverseProject < ActiveRecord::Base
  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'projects'

  DEFAULT_ZOO_PROJECT_LANG = "en"

  def self.import_zoo_projects(projects=nil)
    zoo_projects_scope(projects).find_each do |zoo_project|
      zoo_project.import
    end
  end

  def import
    zooniverse_user
    migrated_project = Project.find_or_initialize_by(name: formatted_name, migrated: true) do |pp|
      pp.display_name = self.name
      pp.private = false
      pp.primary_language = DEFAULT_ZOO_PROJECT_LANG
      pp.owner = zooniverse_user
      pp.project_contents << legacy_project_contents
      pp.configuration = project_configuration(pp)
      pp.redirect = URI::HTTP.build(host: self.location).to_s
    end
    migrated_project.save!
  end

  private

  def self.zoo_projects_scope(projects)
    if projects.blank?
      self
    else
      self.where(name: projects)
    end
  end

  def formatted_name
    self.name.gsub(/-/, "").gsub(/\s+/, "_").underscore
  end

  def preferences_obj
    {
      zoo_home_project_id: self.id,
      legacy_attributes: legacy_attributes
    }
  end

  def legacy_attributes
    {
      status:   self.status,
      released: self.released,
      category:	self.category,
      partners: self.partners,
      credit:   self.credit,
      token:    self.token
    }.keep_if { |k,v| !v.blank? }
  end

  def legacy_project_contents
    ProjectContent.new do |pc|
      pc.title = self.name
      pc.description = self.name
      pc.language = DEFAULT_ZOO_PROJECT_LANG
    end
  end

  def zooniverse_user
    @zoo_user ||= User.find_by!(login: "zooniverse")
  end

  def project_configuration(zoo_project)
    (zoo_project.configuration || {}).merge(preferences_obj)
  end
end
