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
end
