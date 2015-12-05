require 'spec_helper'

describe Subjects::SetMemberSubjectSelector do
  let(:project) { create :project, workflows: build_list(:workflow, 1) }
  let(:subject_set) { create :subject_set, project: project }
  let(:subject) { create :subject, project: project, subject_sets: [subject_set]}
  let(:seen_subject) { create(:subject, project: project, subject_sets: [subject_set]) }

  let(:count) { create(:subject_workflow_count, subject: subject, workflow: project.workflows.first) }
  let(:user) { create(:user) }
  let(:user_seen_subject) { create(:user_seen_subject, user: user, workflow: count.workflow, subject_ids: [seen_subject.id]) }
  let(:selector_class) { Subjects::SetMemberSubjectSelector }

  before do
    count.workflow.subject_sets = count.subject.subject_sets
    count.workflow.save!
  end

  context 'when there is no user' do
    let(:workflow) { create(:workflow_with_subjects) }
    let(:selector) { selector_class.new(workflow, nil) }

    context 'when the workflow is not finished' do
      it 'should select from the non retired remaining subjects' do
        expect(SetMemberSubject).to receive(:non_retired_for_workflow).with(workflow).and_call_original
        selector.set_member_subjects
      end

      context "when the workflow is finished" do

        it "should select the whole set of workflow set_member_subjects" do
          allow(workflow).to receive(:finished?).and_return(true)
          aggregate_failures "select all" do
            expect(selector).to receive(:select_all_workflow_set_member_subjects).and_call_original
            expect(selector.set_member_subjects).to match_array(workflow.set_member_subjects)
          end
        end
      end

      context "when there all the data is retired" do

        it "should not attempt to select the unseen for a user" do
          allow(selector).to receive(:select_non_retired).and_return(SetMemberSubject.none)
          aggregate_failures "select" do
            expect(selector).not_to receive(:select_unseen_for_user)
            expect(selector.set_member_subjects).to be_empty
          end
        end
      end
    end
  end

  context 'when there is a user and they have participated before' do
    before { allow_any_instance_of(selector_class).to receive(:select_from_all?).and_return(false) }

    let(:sms_to_classify) { selector_class.new(count.workflow, user).set_member_subjects }

    it 'does not include subjects that have been seen' do
      user_seen_subject
      expect(sms_to_classify).to eq([count.subject.set_member_subjects.first])
    end

    it 'does not include subjects that are retired' do
      sms = create(:set_member_subject, subject_set: subject_set)
      count.retire!
      expect(sms_to_classify).to eq([sms])
    end

    context "when a user has seen all non-retired" do

      before(:each) do
        user_seen_subject
        create(:subject_workflow_count, subject: seen_subject, workflow: count.workflow)
        count.retire!
      end

      it "should return something to classify" do
        expect(sms_to_classify).to_not be_empty
      end

      it 'does not include subjects the user has seen' do
        user_seen_subject
        expect(sms_to_classify).to eq([count.subject.set_member_subjects.first])
      end
    end

    context "when there are set_member_subjects from other workfow" do
      it "should only return set_member_subjects from the set workflow" do
        sms = create(:set_member_subject)
        expect(sms_to_classify).to eq([count.subject.set_member_subjects.first])
      end
    end
  end
end
