require 'spec_helper'

describe SetMemberSubject, :type => :model do

  let(:set_member_subject) { build(:set_member_subject) }
  let(:locked_factory) { :set_member_subject }
  let(:locked_update) { {state: 1} }

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

  describe "::available" do
    context "when the workflow is finished" do
    end

    context "when the user is finished with the workflow" do
    end

    context "when workflow is unfinished" do
      
    end
  end

  describe "#retired_workflows", :focus do
    let(:subject_set) { create(:subject_set) }
    let(:workflows) { create_list(:workflow, 2, subject_sets: [subject_set])}

    subject do
      create(:set_member_subject,
             subject_set: subject_set,
             retired_workflows: workflows)
    end

    context "when reloaded" do
      it "should belong to many retired_workflows" do
        subject.reload
        expect(subject.retired_workflows).to include(*workflows)
      end

      it "should record the id of the retired workflows it belongs to" do
        subject.reload
        expect(subject.retired_workflow_ids).to eq(workflows.map(&:id))
      end
    end

    context "without reloading" do
      it "should belong to many retired_workflows" do
        expect(subject.retired_workflows).to include(*workflows)
      end

      it "should record the id of the retired workflows it belongs to" do
        expect(subject.retired_workflow_ids).to eq(workflows.map(&:id))
      end
    end

    it "should be able to join the associated models" do
      subject
      rw = SetMemberSubject.joins(:retired_workflows)
        .where(workflows: { id: workflows.first.id }).first

      expect(rw).to eq(subject)
    end
  end
end
