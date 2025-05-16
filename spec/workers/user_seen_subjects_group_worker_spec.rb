# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSeenSubjectsGroupWorker, sidekiq: :inline do
  let(:workflow) { create(:workflow) }
  let(:user) { workflow.project.owner }

  it 'queues UserSeenSubjectsGroupWorker' do
    allow(UserSeenSubjectsWorker)
      .to receive(:perform_async)
      .with(
        user.id,
        workflow.id,
        [1, 2]
      )
    described_class.new.perform([
                                  { user_id: user.id, workflow_id: workflow.id, subject_ids_arr: [1, 2] }
                                ])
    expect(UserSeenSubjectsWorker)
      .to have_received(:perform_async)
      .with(
        user.id,
        workflow.id,
        [1, 2]
      )
  end

  it 'queues UserSeenSubjectsGroupWorker with merged subject_ids_arr of same user and workflow' do
    allow(UserSeenSubjectsWorker)
      .to receive(:perform_async)
      .with(
        user.id,
        workflow.id,
        [1, 2, 3, 4]
      )

    described_class.new.perform([
                                  { user_id: user.id, workflow_id: workflow.id, subject_ids_arr: [1, 2] },
                                  { user_id: user.id, workflow_id: workflow.id, subject_ids_arr: [3, 4] }
                                ])
    expect(UserSeenSubjectsWorker)
      .to have_received(:perform_async)
      .with(
        user.id,
        workflow.id,
        [1, 2, 3, 4]
      )
  end

  it 'queues UserSeenSubjectsGroupWorker with unmerged subject_ids_arr for unrelated user-workflow combos' do
    other_workflow = create(:workflow)

    allow(UserSeenSubjectsWorker)
      .to receive(:perform_async)
      .with(
        user.id,
        workflow.id,
        [1, 2]
      )

    allow(UserSeenSubjectsWorker)
      .to receive(:perform_async)
      .with(
        user.id,
        other_workflow.id,
        [3, 4]
      )

    described_class.new.perform([
                                  { user_id: user.id, workflow_id: workflow.id, subject_ids_arr: [1, 2] },
                                  { user_id: user.id, workflow_id: other_workflow.id, subject_ids_arr: [3, 4] }
                                ])
    expect(UserSeenSubjectsWorker)
      .to have_received(:perform_async)
      .with(
        user.id,
        workflow.id,
        [1, 2]
      )

    expect(UserSeenSubjectsWorker)
      .to have_received(:perform_async)
      .with(
        user.id,
        other_workflow.id,
        [3, 4]
      )
  end
end
