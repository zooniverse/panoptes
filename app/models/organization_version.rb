class OrganizationVersion < ActiveRecord::Base
  belongs_to :organization

  def self.build_from(organization)
    version = new
    version.organization = organization
    version.display_name = organization.display_name
    version.description = organization.description
    version.introduction = organization.introduction
    version.urls = organization.urls
    version.url_labels = organization.url_labels
    version.announcement = organization.announcement
    version
  end

  def self.create_from(organization)
    version = build_from(organization)
    version.save!
    version
  end
end
