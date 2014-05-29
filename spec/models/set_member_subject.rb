require 'spec_helper'

describe GroupedSubject, :type => :model do
  let(:grouped_subject) { create(:grouped_subject) }
  it "should have a valid factory" do
    expect(build(:grouped_subject)).to be_valid
  end

  describe "#subject_group" do
    it "must have a subject group" do
      expect(build(:grouped_subject, subject_group: nil)).to_not be_valid
    end

    it "should belong to a subject group" do
      expect(grouped_subject.subject_group).to be_a(SubjectGroup)
    end
  end

  describe "#subject" do
    it "must have a subject" do
      expect(build(:grouped_subject, subject: nil)).to_not be_valid
    end

    it "should belong to a subject" do
      expect(grouped_subject.subject).to be_a(Subject)
    end
  end
end
