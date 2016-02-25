require 'spec_helper'

describe Subjects::SetMemberSubjectSelector do

  def update_set_sms_count(subject_set)
    sms_count = subject_set.set_member_subjects.count
    subject_set.update_attribute(:set_member_subjects_count, sms_count)
  end

  let(:project) { create(:project_with_workflow) }
  let(:workflow) { project.workflows.first }
  let(:subject_set) do
    create(:subject_set, workflows: [workflow], project: project)
  end
  let!(:subject) do
    create(:subject, project: project, subject_sets: [subject_set])
  end
  let(:seen_subject) do
    create(:subject, project: project, subject_sets: [subject_set])
  end
  let(:non_retired_unseen) do
    create(:subject, project: project, subject_sets: [subject_set])
  end
  let(:count) do
    create(:subject_workflow_count, subject: subject, workflow: workflow)
  end
  let(:user) { create(:user) }
  let(:user_seen_subject) do
    create(:user_seen_subject, user: user, workflow: workflow, subject_ids: [seen_subject.id])
  end
  let(:selector_class) { Subjects::SetMemberSubjectSelector }

  before do
    non_retired_unseen
    update_set_sms_count(subject_set)
  end

  context 'when there is no user' do
    let(:selector) { selector_class.new(workflow, nil) }

    context 'when the workflow is not finished' do
      it 'should select from the non retired remaining subjects' do
        expect(SetMemberSubject)
          .to receive(:non_retired_for_workflow)
          .with(workflow)
          .and_call_original
        selector.set_member_subjects
      end
    end

    context "when the workflow is finished" do
      it "should select the whole set of workflow set_member_subjects", :aggregate_failures do
        allow(workflow).to receive(:finished?).and_return(true)
        expect(selector)
          .to receive(:select_all_workflow_set_member_subjects)
          .and_call_original
        expect(selector.set_member_subjects)
          .to match_array(workflow.set_member_subjects)
      end
    end

    context "when there all the data is retired" do
      it "should not attempt to select the unseen for a user", :aggregate_failures do
        allow(selector).to receive(:select_non_retired)
          .and_return(SetMemberSubject.none)
        expect(selector).not_to receive(:select_unseen_for_user)
        expect(selector.set_member_subjects).to be_empty
      end
    end
  end

  context 'when there is a user' do
    let(:sms_to_classify) do
      selector_class.new(workflow, user).set_member_subjects
    end

    context "they have not participated before" do
      it 'does not include subjects that are retired' do
        retired_sms = count.set_member_subjects
        count.touch(:retired_at)
        expect(sms_to_classify).not_to include(*retired_sms)
      end
    end

    context "they have participated before" do
      before do
        user_seen_subject
        update_set_sms_count(subject_set)
      end

      it 'does not include subjects the user has seen' do
        expect(sms_to_classify).not_to include(seen_subject)
      end

      it 'does not include subjects that are retired' do
        retired_sms = count.set_member_subjects
        count.touch(:retired_at)
        expect(sms_to_classify).not_to include(*retired_sms)
      end

      context "when a user has seen all non-retired" do
        before(:each) do
          UserSeenSubject.add_seen_subjects_for_user(
            user: user,
            workflow: workflow,
            subject_ids: non_retired_unseen.id
          )
          count.touch(:retired_at)
        end

        it "should return something to classify" do
          expect(sms_to_classify).to_not be_empty
        end

        it 'returns only the retired data the user has not seen' do
          expect(sms_to_classify).to match_array(subject.set_member_subjects)
        end
      end

      context "when there are set_member_subjects from another workfow" do
        it "should only return set_member_subjects from the set workflow" do
          sms = create(:set_member_subject)
          workflow_smses = [ subject, non_retired_unseen]
            .map(&:set_member_subjects)
            .flatten
          expect(sms_to_classify).to match_array(workflow_smses)
        end
      end
    end
  end
end
