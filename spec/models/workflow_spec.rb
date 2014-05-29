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

  describe "#subject_sets" do
    let(:workflow) { create(:workflow_with_subject_sets) }

    it "should have many subject sets" do
      expect(workflow.subject_sets).to all( be_a(SubjectSet) )
    end
  end
end
