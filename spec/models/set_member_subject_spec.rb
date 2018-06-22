require 'spec_helper'

describe SetMemberSubject, :type => :model do
  let(:set_member_subject) { build(:set_member_subject) }
  let(:locked_factory) { :set_member_subject }
  let(:locked_update) { {state: 1} }

  it "should have a valid factory" do
    expect(set_member_subject).to be_valid
  end

  it "should be invalid with a duplicate subject_id to subject_set_id" do
    set_member_subject.save
    dup = build(:set_member_subject,
      subject: set_member_subject.subject,
      subject_set: set_member_subject.subject_set)
    expect(dup).to be_invalid
  end

  it "should have a random value when created" do
    expect(create(:set_member_subject).random).to_not be_nil
  end

  describe "::by_subject_workflow" do
    it "should retrieve and object by subject and workflow id" do
      set_member_subject.save!
      sid = set_member_subject.subject_id
      wid = set_member_subject.subject_set.workflows.first.id
      expect(SetMemberSubject.by_subject_workflow(sid, wid)).to include(set_member_subject)
    end
  end

  describe ":by_workflow" do
    it "should retun an empty set" do
      workflow = create(:workflow)
      expect(SetMemberSubject.by_workflow(workflow)).to be_empty
    end

    context "when a workflow sms exist" do
      let(:workflow_sms) { create(:set_member_subject) }
      let(:workflow) { workflow_sms.workflows.first }

      it "should return the workflow sms" do
        expect(SetMemberSubject.by_workflow(workflow)).to eq([workflow_sms])
      end

      context "when another workflow sms exists" do

        it "should only return the workflow sms" do
          create(:set_member_subject)
          expect(SetMemberSubject.by_workflow(workflow)).to eq([workflow_sms])
        end
      end
    end
  end

  describe ":non_retired_for_workflow" do
    let(:set_member_subject) { create(:set_member_subject) }
    let(:workflow) { create(:workflow, subject_sets: [set_member_subject.subject_set]) }
    let(:count) { create(:subject_workflow_status, subject: set_member_subject.subject, workflow: workflow) }

    it "should not return any smses with no linked workflow status instances" do
      expect(SetMemberSubject.non_retired_for_workflow(workflow.id)).not_to include(set_member_subject)
    end

    it "should return the sms with linked workflow status instances" do
      count
      expect(SetMemberSubject.non_retired_for_workflow(workflow.id)).to include(set_member_subject)
    end

    context "when none are retired" do
      it "should return the workflow's non retired sms" do
        count
        expect(SetMemberSubject.non_retired_for_workflow(workflow.id)).to include(set_member_subject)
      end
    end

    context "when the workflow sms is retired" do
      it "should return an empty set" do
        count.retire!
        expect(SetMemberSubject.non_retired_for_workflow(workflow.id)).to be_empty
      end
    end

    context 'when the workflow sms is retired for another workflow' do
      it 'should return the sms' do
        count
        workflow2 = create(:workflow, subject_sets: [set_member_subject.subject_set])
        count2 = create(:subject_workflow_status, subject: set_member_subject.subject, workflow: workflow2)
        count2.retire!
        expect(SetMemberSubject.non_retired_for_workflow(workflow.id)).to include(set_member_subject)
      end
    end
  end

  describe ":retired_for_workflow" do
    let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
    let(:sms) { workflow.set_member_subjects.first }
    let(:count) do
      create(:subject_workflow_status, subject: sms.subject, workflow: workflow)
    end

    it "should not return any smses with no workflow status instances" do
      expect(SetMemberSubject.retired_for_workflow(workflow.id)).not_to include(sms)
    end

    context "when none are retired" do
      it "should return an empty set" do
        count
        expect(SetMemberSubject.retired_for_workflow(workflow.id)).to be_empty
      end
    end

    context "when the workflow sms is retired" do
      it "should return the sms id" do
        count.retire!
        binding.pry
        expect(SetMemberSubject.retired_for_workflow(workflow.id)).to include(sms)
      end
    end

    context 'when the workflow sms is retired for another workflow' do
      it 'should not return the sms' do
        workflow2 = create(:workflow, subject_sets: [sms.subject_set])
        create(:subject_workflow_status, subject: sms.subject, workflow: workflow2, retired_at: DateTime.now)
        expect(SetMemberSubject.retired_for_workflow(workflow.id)).not_to include(sms)
      end
    end
  end

  context "with seen data" do
    let(:user) { create(:user) }
    let(:workflow) { create(:workflow_with_subjects) }
    let(:smses){ workflow.set_member_subjects }
    let(:uss) do
      create(:user_seen_subject, workflow: workflow, user: user, subject_ids: subject_ids)

      subject_ids.each do |subject_id|
        create(:classification, subjects: Subject.where(id: subject_id), user: user, workflow: workflow)
      end
    end
    let!(:another_workflow_sms) { create(:set_member_subject) }

    before do
      allow_any_instance_of(CodeExperiment).to receive(:enabled?).and_return(true)
      uss
    end

    describe ":unseen_for_user_by_workflow" do
      context "when the user has not seen any workflow subjects" do
        let(:subject_ids) { [] }

        it "should return the all the worflow set_member_subjects" do
          expect(SetMemberSubject.unseen_for_user_by_workflow(user, workflow)).to match_array(smses)
        end
      end

      context "when the user has seen all the workflow subjects" do
        let(:subject_ids) { [smses.map(&:subject_id)] }

        it "should return an empty set" do
          expect(SetMemberSubject.unseen_for_user_by_workflow(user, workflow)).to be_empty
        end
      end
    end

    describe ":seen_for_user_by_workflow" do
      context "when the user has not seen any workflow subjects" do
        let(:subject_ids) { [] }

        it "should return the all the worflow set_member_subjects" do
          expect(SetMemberSubject.seen_for_user_by_workflow(user, workflow)).to be_empty
        end
      end

      context "when the user has seen all the workflow subjects" do
        let(:subject_ids) { [smses.map(&:subject_id)] }

        it "should return an empty set" do
          expect(SetMemberSubject.seen_for_user_by_workflow(user, workflow)).to match_array(smses)
        end
      end
    end
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
end
