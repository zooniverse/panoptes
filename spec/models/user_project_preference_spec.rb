require 'spec_helper'

RSpec.describe UserProjectPreference, :type => :model do
  let(:user_project) { build(:user_project_preference) }
  let(:factory) { :user_project_preference }
  let(:valid_roles)  { ["tester", "collaborator"] }
  let(:roles_field) { :roles }

  it 'should have a valid factory' do
    expect(user_project).to be_valid
  end

  it 'should require a project to be valid' do
    expect(build(:user_project_preference, project: nil)).to_not be_valid
  end

  it 'should require a user to be valid' do
    expect(build(:user_project_preference, user: nil)).to_not be_valid
  end

  it_behaves_like "roles validated"
end
