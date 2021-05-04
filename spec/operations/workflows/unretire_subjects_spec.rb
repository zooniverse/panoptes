# frozen_string_literal: true

require 'spec_helper'

describe Workflows::UnretireSubjects do
  let(:api_user) { ApiUser.new(build_stubbed(:user)) }
  let(:workflow) { create(:workflow) }
  let(:subject_set) do
    create(:subject_set_with_subjects, num_subjects: 2, project: workflow.project, workflows: [workflow])
  end
  let(:subject1) { subject_set.subjects.first }
  let(:subject2) { subject_set.subjects.last }
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
    run_params = params.except(:subject_id)
    operation.run!(run_params.merge(subject_ids: [subject1.id, subject2.id]))
    expect(UnretireSubjectWorker)
      .to have_received(:perform_async)
      .with(workflow.id, [subject1.id, subject2.id])
  end

  it 'is invalid with a missing workflow_id param' do
    result = operation.run(params.except(:workflow_id))
    expect(result).not_to be_valid
  end
end
