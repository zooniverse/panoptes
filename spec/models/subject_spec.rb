require 'spec_helper'

describe Subject, :type => :model do
  it "should have a valid factory" do
    expect(build(:subject)).to be_valid
  end

  describe "#collections" do
    let(:subject) { create(:subject_with_collections) }

    it "should belong to many collections" do
      expect(subject.collections).to all( be_a(Collection) )
    end
  end

  describe "#subject_groups" do
    let(:subject) { create(:subject_with_subject_groups) }

    it "should belong to many subject groups" do 
      expect(subject.subject_groups).to all( be_a(SubjectGroup) )
    end
  end

  describe "#grouped_subjects" do
    let(:grouped_subjects) { create(:subject_with_subject_groups) }

    it "should have many grouped subjects" do
      expect(subject.grouped_subjects).to all( be_a(GroupedSubject) )
    end
  end
end
