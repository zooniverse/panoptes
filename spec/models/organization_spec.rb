require 'spec_helper'

RSpec.describe Organization, type: :model do
  let(:organization) { build(:organization) }

  it "should have a valid factory" do
    expect(organization).to be_valid
  end

  it 'should require a primary language field to be set' do
    expect(build(:organization, primary_language: nil)).to_not be_valid
  end

  describe "links" do
    let(:user) { ApiUser.new(create(:user)) }

    it "should allow projects to link when user has update permissions" do
      expect(Organization).to link_to(Project).given_args(user)
                          .with_scope(:scope_for, :update, user)
    end
  end

  describe "#organization_roles" do
    let!(:preferences) do
      [create(:access_control_list, resource: organization, roles: []),
       create(:access_control_list, resource: organization, roles: ["tester"]),
       create(:access_control_list, resource: organization, roles: ["collaborator"])]
    end

    it 'should include models with assigned roles' do
      expect(organization.organization_roles).to include(*preferences[1..-1])
    end

    it 'should not include models without assigned roles' do
      expect(organization.organization_roles).to_not include(preferences[0])
    end
  end
end
