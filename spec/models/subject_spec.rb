require 'spec_helper'

RSpec.describe Subject, :type => :model do

  let(:subject) { build(:subject) }

  it "should have a valid factory" do
    expect(subject).to be_valid
  end

  it "should be invalid without a project_id" do
    subject.project = nil
    expect(subject).to_not be_valid
  end

  it "should be invalid without an owner_id" do
    subject.owner = nil
    expect(subject).to_not be_valid
  end

  describe "#collections" do
    let(:subject) { create(:subject_with_collections) }

    it "should belong to many collections" do
      expect(subject.collections).to all( be_a(Collection) )
    end
  end

  describe "#subject_sets" do
    let(:subject) { create(:subject_with_subject_sets) }

    it "should belong to many subject sets" do
      expect(subject.subject_sets).to all( be_a(SubjectSet) )
    end
  end

  describe "#set_member_subjects" do
    let(:set_member_subjects) { create(:subject_with_subject_sets) }

    it "should have many set_member subjects" do
      expect(subject.set_member_subjects).to all( be_a(SetMemberSubject) )
    end
  end
end
