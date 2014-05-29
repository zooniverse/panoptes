require 'spec_helper'

describe SubjectSet, :type => :model do
  let(:subject_set) { create(:subject_set) }

  it "should have a valid factory" do
    expect(build(:subject_set)).to be_valid
  end

  describe "#project" do
    it "should have a project" do
      expect(subject_set.project).to be_a(Project)
    end

    it "should not be valid without a project" do
      expect(build(:subject_set, project: nil)).to_not be_valid
    end
  end

  describe "#workflows" do
    let(:subject_set) { create(:subject_set_with_workflows) }

    it "should have many workflows" do
      expect(subject_set.workflows).to all( be_a(Workflow) )
    end
  end

  describe "#subjects" do
    let(:subject_set) { create(:subject_set_with_subjects) } 

    it "should have many subjects" do
      expect(subject_set.subjects).to all( be_a(Subject) )
    end
  end

  describe "#seted_subjects" do 
    let(:subject_set) { create(:subject_set_with_subjects) }

    it "should have many seted subjects" do
      expect(subject_set.set_member_subjects).to all( be_a(SetMemberSubject) )
    end
  end
end
