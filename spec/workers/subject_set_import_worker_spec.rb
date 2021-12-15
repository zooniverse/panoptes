# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectSetImportWorker do
  # avoid re-running the import on failures
  it 'does not retry imports' do
    retry_count = described_class.get_sidekiq_options['retry']
    expect(retry_count).to eq(0)
  end

  describe '#perform' do
    let(:import_double) do
      instance_double(SubjectSetImport, id: 1, import!: true, subject_set_id: 1)
    end
    let(:count_worker_double) do
      instance_double(SubjectSetSubjectCounterWorker, perform: true)
    end
    let(:manifest_row_count) { 2 }

    before do
      allow(SubjectSetImport).to receive(:find).and_return(import_double)
      allow(SubjectSetSubjectCounterWorker).to receive(:new).and_return(count_worker_double)
    end

    it 'runs the subjet set import code' do
      described_class.new.perform(import_double.id, manifest_row_count)
      expect(import_double).to have_received(:import!).with(manifest_row_count)
    end

    it 'calls the subject set counter worker inline' do
      described_class.new.perform(import_double.id, manifest_row_count)
      expect(count_worker_double).to have_received(:perform).with(import_double.subject_set_id)
    end
  end
end
