require 'spec_helper'

RSpec.describe UserProjectPreference, :type => :model do
  let(:user_project) { build(:user_project_preference) }
  let(:factory) { :user_project_preference }

  it_behaves_like "has preferences scope"

  it 'should have a valid factory' do
    expect(user_project).to be_valid
  end

  it 'should require a project to be valid' do
    expect(build(:user_project_preference, project: nil)).to_not be_valid
  end

  it 'should require a user to be valid' do
    expect(build(:user_project_preference, user: nil)).to_not be_valid
  end

  it 'should increment a count on the associated project' do
    project = create(:project)
    expect do
      create(:user_project_preference, project: project)
      project.reload
    end.to change{project.classifiers_count}.from(0).to(1)
  end
end
