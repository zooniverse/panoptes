require 'spec_helper'

describe Project, :type => :model do
  let(:project) { build(:project) }
  let(:owned) { project }
  let(:not_owned) { build(:project, owner: nil) }
  let(:subject_relation) { create(:project_with_subjects) }
  let(:activatable) { project }
  let(:translatable) { create(:project_with_contents) }
  let(:primary_language_factory) { :project }

  it_behaves_like "is ownable"
  it_behaves_like "has subject_count"
  it_behaves_like "activatable"
  it_behaves_like "is translatable"

  it "should have a valid factory" do
    expect(project).to be_valid
  end
  
  it { is_expected.to permit_field(:visible_to).for_action(:show) }
  it { is_expected.to permit_roles(:collaborator).for_action(:update) }

  it 'should require unique names for an ower' do
    owner = create(:user)
    expect(create(:project, name: "hi_fives", owner: owner)).to be_valid
    expect(build(:project, name: "hi_fives", owner: owner)).to_not be_valid
  end

  it 'should not require name uniquenames between owners' do
    expect(create(:project, name: "test_project", owner: create(:user))).to be_valid
    expect(create(:project, name: "test_project", owner: create(:user))).to be_valid
  end

  it 'should require unique dispalys name for an owner' do
    owner = create(:user)
    expect(create(:project, display_name: "hi fives", owner: owner)).to be_valid
    expect(build(:project, display_name: "hi fives", owner: owner)).to_not be_valid
  end
  
  it 'should not require display name uniquenames between owners' do
    expect(create(:project, display_name: "test project", owner: create(:user))).to be_valid
    expect(create(:project, display_name: "test project", owner: create(:user))).to be_valid
  end

  describe "links" do
    let(:user) { ApiUser.new(create(:user)) }
    
    it "should allow workflows to link when user has update permissions" do
      expect(Project).to link_to(Workflow).given_args(user)
                          .with_scope(:scope_for, :update, user)
    end
    
    it "should allow subject_sets to link when user has update permissions" do
      expect(Project).to link_to(SubjectSet).given_args(user)
                          .with_scope(:scope_for, :update, user)
    end
    
    it "should allow subjects to link when user has update permissions" do
      expect(Project).to link_to(Subject).given_args(user)
                          .with_scope(:scope_for, :update, user)
    end

    it "should allow collections to link user has show permissions" do
      expect(Project).to link_to(Collection).given_args(user)
                          .with_scope(:scope_for, :show, user)
    end
  end
  
  describe "#workflows" do
    let(:project) { create(:project_with_workflows) }

    it "should have many workflows" do
      expect(project.workflows).to all( be_a(Workflow) )
    end
  end

  describe "#subject_sets" do
    let(:project) { create(:project_with_subject_sets) }

    it "should have many subject_sets" do
      expect(project.subject_sets).to all( be_a(SubjectSet) )
    end
  end

  describe "#classifications" do
    let(:relation_instance) { project }

    it_behaves_like "it has a classifications assocation"
  end

  describe "#classifcations_count" do
    let(:relation_instance) { project }

    it_behaves_like "it has a cached counter for classifications"
  end

  describe "#subjects" do
    let(:relation_instance) { project }

    it_behaves_like "it has a subjects association"
  end

  describe "#project_roles" do
    let!(:preferences) do
      [create(:user_project_preference, project: project, roles: []),
       create(:user_project_preference, project: project, roles: ["tester"]),
       create(:user_project_preference, project: project, roles: ["collaborator"])]
    end

    it 'should include models with assigned roles' do
      expect(project.project_roles).to match_array(preferences[1..-1])
    end

    it 'should not include models without assigned roles' do
      expect(project.project_roles).to_not include(preferences[0])
    end
  end

  describe "::translatable_by" do
    let(:users) { create_list(:user, 2) }
    let(:private_project) { create(:project, visible_to: ["collaborator"]) }
    let!(:upp) do
      create(:user_project_preference, user: users.first, project: project, roles: ["translator"])
    end

    it 'should include projects a user is a translator for' do
      expect(Project.translatable_by(users.first)).to match_array([project])
    end

    it 'should not include projects a user is not a translator for' do
      expect(Project.translatable_by(users.first)).to_not include(private_project)
    end

    it 'should by empty when a user not a translator on any project' do
      expect(Project.translatable_by(users[1])).to be_empty
    end
  end

  describe "#is_translator" do
    let(:user) { create(:user) }
    context "when user has a translator role" do
      let!(:upp) do
        create(:user_project_preference, user: user, project: project, roles: ["translator"])
      end
      
      it 'should return truthy' do
        expect(project.is_translator?(user)).to be_truthy
      end
    end

    context "when a user does not have a translator role" do
      it 'should return false if a user is not a translator' do
        expect(project.is_translator?(user)).to be_falsy
      end
    end
  end
end
