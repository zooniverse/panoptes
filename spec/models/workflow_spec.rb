require 'spec_helper'

describe Workflow, :type => :model do
  let(:workflow) { create(:workflow) } 
  
  it "should have a valid factory" do
    expect(build(:workflow)).to be_valid
  end

  describe "#project" do
    it "should have a project" do
      expect(workflow.project).to be_a(Project)
    end

    it "should belong to a project to be valid" do
      expect(build(:workflow, project: nil)).to_not be_valid
    end
  end

  describe "#subject_groups" do
    let(:workflow) { create(:workflow_with_subject_groups) }

    it "should have many subject groups" do
      expect(workflow.subject_groups).to all( be_a(SubjectGroup) )
    end
  end
end
