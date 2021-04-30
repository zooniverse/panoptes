# frozen_string_literal: true

require 'spec_helper'

describe Workflows::UnretireSubjects do
  let(:api_user) { ApiUser.new(build_stubbed(:user)) }
  let(:workflow) { create(:workflow) }
  let(:subject_set) { create(:subject_set, project: workflow.project, workflows: [workflow]) }
  let(:subject_set_id) { subject_set.id }
  let(:subject1) { create(:subject, subject_sets: [subject_set]) }
  let(:subject_workflow_count) { create }
  let(:params) do
    {
      workflow_id: workflow.id,
      subject_id: subject1.id
    }
  end
  let(:operation) { described_class.with(api_user: api_user) }
  before do 
    allow(UnretireSubjectWorker).to receive(:perform_async).and_return(true)
  end

  it 'calls the unretirement worker with subject_id' do
    operation.run!(params)
    expect(UnretireSubjectWorker)
      .to have_received(:perform_async)
      .with(workflow.id, [subject1.id])
  end

  it 'calls unretirement worker with subject_ids' do
    subject2 = create(:subject, subject_sets: [subject_set])
    subject_ids = [subject1.id, subject2.id]
    run_params = params.except(:subject_id)
    operation.run!(run_params.merge(subject_ids: subject_ids))
    expect(UnretireSubjectWorker)
      .to have_received(:perform_async)
      .with(workflow.id, subject_ids)
  end

  it 'is invalid with a missing workflow_id param' do
    result = operation.run(params.except(:workflow_id))
    expect(result).not_to be_valid
  end
end
