require 'spec_helper'

describe Project, :type => :model do
  it "should have a valid factory" do
    expect(build(:project)).to be_valid
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

  describe "#owner" do
    let(:project) { create(:project) }

    it "should have a user owner" do
      expect(project.owner).to be_a(User)
    end

    it "shoutl not be valid without a user owner" do
      expect(build(:project, owner: nil)).to_not be_valid
    end
  end
end
