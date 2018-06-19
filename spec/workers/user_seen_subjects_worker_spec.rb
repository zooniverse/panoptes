require 'spec_helper'

RSpec.describe UserSeenSubjectsWorker do
  let(:workflow) { create(:workflow) }
  let(:user) { workflow.project.owner }
  let(:subject_ids) { [1, 2]}

  it 'should call add_seen_subjects_for_user' do
    expect(UserSeenSubject)
      .to receive(:add_seen_subjects_for_user)
      .with({user: user, workflow: workflow, subject_ids: subject_ids})
    subject.perform(user.id, workflow.id, subject_ids)
  end
end
