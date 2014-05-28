require 'spec_helper'

describe SubjectGroup, :type => :model do
  let(:subject_group) { create(:subject_group) }

  it "should have a valid factory" do
    expect(build(:subject_group)).to be_valid
  end

  describe "#project" do
    it "should have a project" do
      expect(subject_group.project).to be_a(Project)
    end

    it "should not be valid without a project" do
      expect(build(:subject_group, project: nil)).to_not be_valid
    end
  end

  describe "#workflows" do
    let(:subject_group) { create(:subject_group_with_workflows) }

    it "should have many workflows" do
      expect(subject_group.workflows).to all( be_a(Workflow) )
    end
  end
end
