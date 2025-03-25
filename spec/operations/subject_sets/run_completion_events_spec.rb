# frozen_string_literal: true

require 'spec_helper'

describe SubjectSets::RunCompletionEvents do
  let(:subject_set) { create(:subject_set) }
  let(:workflow) { subject_set.workflows.first }
  let(:operation_params) do
    { subject_set: subject_set, workflow: workflow }
  end

  it 'validates subject_set param' do
    outcome = described_class.run(operation_params.except(:subject_set))
    expect(outcome.errors.full_messages).to include('Subject set is required')
  end

  it 'validates workflow param' do
    outcome = described_class.run(operation_params.except(:workflow))
    expect(outcome.errors.full_messages).to include('Workflow is required')
  end

  it 'does not run the SubjectSetCompletedMailerWorker' do
    allow(SubjectSetCompletedMailerWorker).to receive(:perform_async)
    described_class.run!(operation_params)
    expect(SubjectSetCompletedMailerWorker).not_to have_received(:perform_async)
  end

  it 'does not run the CreateClassificationsExport operation' do
    allow(CreateClassificationsExport).to receive(:with)
    described_class.run!(operation_params)
    expect(CreateClassificationsExport).not_to have_received(:with)
  end

  context 'when the project is configured for subject set completeness events' do
    before do
      allow(subject_set).to receive(:run_completion_events?).and_return(true)
    end

    it 'runs the CreateClassificationsExport operation' do
      operation_double = CreateClassificationsExport.with(api_user: ApiUser.new(nil), object: subject_set)
      allow(operation_double).to receive(:run!)
      allow(CreateClassificationsExport).to receive(:with).and_return(operation_double)
      described_class.run!(operation_params)
      expect(operation_double).to have_received(:run!).with({ media: { metadata: { recipients: [] } } })
    end

    it 'runs the SubjectSetCompletedMailerWorker' do
      allow(SubjectSetCompletedMailerWorker).to receive(:perform_async)
      described_class.run!(operation_params)
      expect(SubjectSetCompletedMailerWorker).to have_received(:perform_async).with(subject_set.id)
    end
  end
end
