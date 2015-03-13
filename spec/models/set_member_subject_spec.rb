require 'spec_helper'

describe SetMemberSubject, :type => :model do

  let(:set_member_subject) { build(:set_member_subject) }
  let(:locked_factory) { :set_member_subject }
  let(:locked_update) { {state: 1} }
  
  it_behaves_like "optimistically locked"

  it "should have a valid factory" do
    expect(set_member_subject).to be_valid
  end

  it "should have a random value when created" do
    expect(create(:set_member_subject).random).to_not be_nil
  end

  describe "#subject_set" do
    it "must have a subject set" do
      set_member_subject.subject_set = nil
      expect(set_member_subject).to_not be_valid
    end

    it "should belong to a subject set" do
      expect(set_member_subject.subject_set).to be_a(SubjectSet)
    end
  end

  describe "#subject" do
    it "must have a subject" do
      set_member_subject.subject = nil
      expect(set_member_subject).to_not be_valid
    end

    it "should belong to a subject" do
      expect(set_member_subject.subject).to be_a(Subject)
    end
  end

  describe "::by_subject_workflow" do
    it "should retrieve and object by subject and workflow id" do
      set_member_subject.save!
      sid = set_member_subject.subject_id
      wid = set_member_subject.subject_set.workflow_id
      expect(SetMemberSubject.by_subject_workflow(sid, wid)).to include(set_member_subject)
    end
  end
end
