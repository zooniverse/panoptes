require 'spec_helper'

describe SetMemberSubjectSelector do
  let(:count) { create(:subject_workflow_count) }
  let(:user) { create(:user) }

  before do
    count.workflow.subject_sets = [count.set_member_subject.subject_set]
    count.workflow.save!
  end

  context 'when there is a user and they have participated before' do
    before { allow_any_instance_of(SetMemberSubjectSelector).to receive(:select_from_all?).and_return(false) }

    it 'does not include subjects that have been seen' do
      seen_subject = create(:subject, subject_sets: [count.set_member_subject.subject_set])
      create(:user_seen_subject, user: user, workflow: count.workflow, subject_ids: [seen_subject.id])

      sms = SetMemberSubjectSelector.new(count.workflow, user).set_member_subjects
      expect(sms).to eq([count.set_member_subject])
    end

    it 'does not include subjects that are retired' do
      count.retire!
      sms = SetMemberSubjectSelector.new(count.workflow, user).set_member_subjects
      expect(sms).to be_empty
    end
  end
end
