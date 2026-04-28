# frozen_string_literal: true

class OrganizationProject < ApplicationRecord
  belongs_to :organization
  belongs_to :project

  validates :organization_id, uniqueness: { scope: :project_id }
end
