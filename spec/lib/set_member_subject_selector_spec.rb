require 'spec_helper'

describe SetMemberSubjectSelector do
  let(:count) { create(:subject_workflow_count) }
  let(:user) { create(:user) }
  let(:seen_subject) { create(:subject, subject_sets: [count.set_member_subject.subject_set]) }

  before do
    count.workflow.subject_sets = [count.set_member_subject.subject_set]
    count.workflow.save!
  end

  context 'when there is a user and they have participated before' do
    before { allow_any_instance_of(SetMemberSubjectSelector).to receive(:select_from_all?).and_return(false) }

    let(:sms_to_classify) { SetMemberSubjectSelector.new(count.workflow, user).set_member_subjects }

    it 'does not include subjects that have been seen' do
      seen_subject = create(:subject, subject_sets: [count.set_member_subject.subject_set])
      create(:user_seen_subject, user: user, workflow: count.workflow, subject_ids: [seen_subject.id])
      expect(sms_to_classify).to eq([count.set_member_subject])
    end

    it 'does not include subjects that are retired' do
      count.retire!
      expect(sms_to_classify).to be_empty
    end

    context "when all the user has seen all non-retired" do

      before(:each) do
        create(:user_seen_subject, user: user, workflow: count.workflow, subject_ids: [seen_subject.id])
        create(:subject_workflow_count, set_member_subject: seen_subject.set_member_subjects.first, workflow: count.workflow)
        count.retire!
      end

      it "should return something to classify" do
        expect(sms_to_classify).to_not be_empty
      end

      it "should select from the whole set of set_member_subjects" do
        expect_any_instance_of(SetMemberSubjectSelector).to receive(:select_all_workflow_set_member_subjects)
        sms_to_classify
      end
    end
  end
end
