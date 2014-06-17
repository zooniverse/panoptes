require 'spec_helper'

describe Workflow, :type => :model do

  let(:workflow) { build(:workflow) }
  let(:subject_relation) { create(:workflow_with_subjects) }

  it_behaves_like "has subject_count"

  it "should have a valid factory" do
    expect(workflow).to be_valid
  end

  describe "#project" do
    let(:workflow) { create(:workflow) }

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

  describe "#classifications" do
    let(:relation_instance) { workflow }

    it_behaves_like "it has a classifications assocation"
  end

  describe "#classifcations_count" do
    let(:relation_instance) { workflow }

    it_behaves_like "it has a cached counter for classifications"
  end
end
