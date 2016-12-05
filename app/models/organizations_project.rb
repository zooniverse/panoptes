class OrganizationsProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :organization
end