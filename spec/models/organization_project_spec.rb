require 'spec_helper'

describe OrganizationProject, type: :model do
  it "has a valid factory" do
    expect(build(:organization_project)).to be_valid
  end

  it "enforces uniqueness on organization and project pairs" do
    organization_project = create(:organization_project)
    duplicate = build(
      :organization_project,
      organization: organization_project.organization,
      project: organization_project.project
    )

    expect(duplicate).to_not be_valid
    expect(duplicate.errors[:organization_id]).to include("has already been taken")
  end
end
