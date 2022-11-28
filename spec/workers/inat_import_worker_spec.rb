# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InatImportWorker do
  # avoid re-running the import on failures
  it 'does not retry imports' do
    retry_count = described_class.get_sidekiq_options['retry']
    expect(retry_count).to eq(0)
  end

  describe '#perform' do
    # An enumerable proxy for the importer's #observations method
    let(:obs_array) { build_list(:observation, 2) }
    let(:api_double) { instance_double(Inaturalist::ApiInterface, observations: obs_array, total_results: 123) }
    let(:ss_import) { instance_double(SubjectSetImport, id: 1, save_imported_row_count: true) }
    let(:import_results_double) do
      instance_double('ActiveRecord::Import::Result', ids: [1, 2], failed_instances: nil)
    end
    let(:importer_double) do
      instance_double(Inaturalist::SubjectImporter, to_subject: true, subject_set_import: ss_import, import_subjects: import_results_double, import_smses: true)
    end
    let(:count_worker_double) do
      instance_double(SubjectSetSubjectCounterWorker, perform: true)
    end

    before do
      allow(Inaturalist::SubjectImporter).to receive(:new).and_return(importer_double)
      allow(Inaturalist::ApiInterface).to receive(:new).and_return(api_double)
      allow(SubjectSetImport).to receive(:new).and_return(ss_import)
      allow(SubjectSetSubjectCounterWorker).to receive(:new).and_return(count_worker_double)
      allow(InatImportCompletedMailerWorker).to receive(:perform_async)
      allow_any_instance_of(described_class).to receive(:import_batch_size).and_return(1)
      allow_any_instance_of(described_class).to receive(:set_status).and_return(true)
      allow(Subject).to receive(:import).and_return(import_results_double)
      allow(SetMemberSubject).to receive(:import).and_return(import_results_double)
      described_class.new.perform(1, 1, 1)
    end

    context 'when the import is successful' do
      it 'runs SubjectImporter#to_subject on each observation in an enumerable' do
        obs_array.each { |obs| expect(importer_double).to have_received(:to_subject).with(obs) }
      end

      it 'invokes the importer to import a batch' do
        expect(importer_double).to have_received(:import_subjects).with([true, true])
      end

      it 'invokes the importer to import SetMemberSubjects' do
        expect(importer_double).to have_received(:import_smses).with(import_results_double)
      end

      it 'calls the subject set import mailer worker' do
        expect(InatImportCompletedMailerWorker).to have_received(:perform_async).with(ss_import.id)
      end

      it 'calls the subject set counter worker inline' do
        expect(count_worker_double).to have_received(:perform).with(1)
      end
    end

    context 'when there is a failure' do
      let(:failed_instances) { [Subject.new(external_id: 1), Subject.new(external_id: 2)] }

      before do
        allow(import_results_double).to receive(:failed_instances).and_return(failed_instances)
        allow(ss_import).to receive(:update_columns).with(any_args).and_return(true)
        allow(ss_import).to receive(:failed_count).and_return(0)
        allow(ss_import).to receive(:failed_uuids).and_return([])
      end

      it 'continues processing' do
        expect { described_class.new.perform(1, 1, 1) }.not_to raise_error
      end

      it 'stores the failed count' do
        described_class.new.perform(1, 1, 1)
        expect(ss_import).to have_received(:update_columns).with(failed_count: 2, failed_uuids: %w[1 2])
      end
    end
  end
end
