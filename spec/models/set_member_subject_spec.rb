require 'spec_helper'

describe SetMemberSubject, :type => :model do

  let(:set_member_subject) { build(:set_member_subject) }
  let(:locked_factory) { :set_member_subject }
  let(:locked_update) { {state: 1} }
  
  it_behaves_like "optimistically locked"

  it "should have a valid factory" do
    expect(set_member_subject).to be_valid
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

  describe "#classifications" do
    let(:relation_instance) { set_member_subject }

    it_behaves_like "it has a classifications assocation"
  end

  describe "#classifcations_count" do
    let(:relation_instance) { set_member_subject }

    it_behaves_like "it has a cached counter for classifications"
  end
end
