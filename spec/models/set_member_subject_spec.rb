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

  describe "::available" do
    let(:workflow) { create(:workflow) }
    let(:subject_set) { create(:subject_set, workflows: [workflow]) }
    let!(:sms) { create_list(:set_member_subject, 2, subject_set: subject_set) }
    let!(:uss) do
      create(:user_seen_subject, workflow: workflow, subject_ids: [sms.first.subject_id])
    end
    let(:user) { uss.user }

    subject { SetMemberSubject.available(workflow, user).pluck(:subject_id) }

    context "when the workflow is finished" do
      let!(:sms) do
        create_list(:set_member_subject, 2, subject_set: subject_set, retired_workflows: [workflow])
      end

      before(:each) do
        workflow.update!(retired_set_member_subjects_count: sms.length)
      end

      it 'should select retired subjects' do
        expect(subject).to include(sms.first.subject_id)
      end
    end

    context "when the user is finished with the workflow" do
      let!(:uss) do
        create(:user_seen_subject, workflow: workflow, subject_ids: sms.map(&:subject_id))
      end

      it 'should select subjects a user has seen' do
        expect(subject).to include(sms.first.subject_id)
      end
    end

    context "when no uss exsits" do
      let!(:uss) { nil }
      let(:user) { create(:user) }

      it 'should return an active subject' do
        expect(subject).to include(*sms.map(&:subject_id))
      end
    end

    context "when workflow is unfinished" do
      let!(:retired_sms) do
        create(:set_member_subject, subject_set: subject_set, retired_workflows: [workflow])
      end

      it 'should select active subjects' do
        expect(subject).to include(sms[1].subject_id)
      end

      it 'should not select retired subjects' do
        expect(subject).to_not include(retired_sms.subject_id)
      end

      it 'should select subjects a user has not seen' do
        expect(subject).to include(sms[1].subject_id)
      end

      it 'should not select subjects a user has seen' do
        expect(subject).to_not include(sms[0].subject_id)
      end
    end
  end

  describe "#retired_workflows" do
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

  describe "#retire_workflow" do
    it 'should add the workflow the retired_workflows relationship' do
      sms = set_member_subject
      sms.save!
      workflow = sms.subject_set.workflows.first
      sms.retire_workflow(workflow)
      sms.reload
      expect(sms.retired_workflows).to include(workflow)
    end
  end

  describe "::by_subject_workflow" do
    it "should retrieve and object by subject and workflow id" do
      set_member_subject.save!
      sid = set_member_subject.subject_id
      wid = set_member_subject.subject_set.workflows.first.id
      expect(SetMemberSubject.by_subject_workflow(sid, wid)).to include(set_member_subject)
    end
  end

  describe "#remove_from_queues" do
    it 'should queue a removal worker' do
      set_member_subject.save!
      expect(QueueRemovalWorker).to receive(:perform_async)
        .with(set_member_subject.id, set_member_subject.subject_set.workflows.pluck(:id))
      set_member_subject.remove_from_queues
    end
  end
end
