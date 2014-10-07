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

  describe "::visible_to" do
    let(:user) { create(:user) }
    let(:actor) { ApiUser.new(user) }
    let(:project) { create(:project, owner: user) }
    let!(:upps) do
      [create(:user_project_preference, project: project),
       create(:user_project_preference, user: user),
       create(:user_project_preference)]
    end
    
    it 'should return any preferences that belong to the user' do
      expect(UserProjectPreference.visible_to(actor)).to include(upps[1])
    end

    it 'should return any preference belongs to projects updatable by user' do
      expect(UserProjectPreference.visible_to(actor)).to include(upps[0])
    end

    it 'should not return preferences a user cannot access' do
      expect(UserProjectPreference.visible_to(actor)).not_to include(upps[2])
    end

    it 'should only return accessable preferences' do
      expect(UserProjectPreference.visible_to(actor)).to match_array(upps[0..1])
    end
  end

  describe "::can_create?" do
    it 'should return truthy when the actor is logged in' do
      actor = ApiUser.new(create(:user))
      expect(UserProjectPreference.can_create?(actor)).to be_truthy
    end

    it 'should return falsy when the actor is not logged in' do
      actor = ApiUser.new(nil)
      expect(UserProjectPreference.can_create?(actor)).to be_falsy
    end
  end

  describe "allowed_to_change?" do
    it 'should be truthy when the actor is the resource user' do
      upp = create(:user_project_preference)
      expect(upp.allowed_to_change?(ApiUser.new(upp.user))).to be_truthy
    end

    it 'should be truthy when the actor can update the project' do
      user = create(:user)
      project = create(:project, owner: user)
      upp = create(:user_project_preference, project: project)
      expect(upp.allowed_to_change?(ApiUser.new(user))).to be_truthy
    end

    it 'should be falsy otherwise' do
      upp = create(:user_project_preference)
      expect(upp.allowed_to_change?(ApiUser.new(create(:user)))).to be_falsy
    end
  end
end
