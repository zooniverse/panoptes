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
    let(:obs_array) { [ double('observation'), double('observation') ] }
    let(:api_double) { instance_double(Inaturalist::ApiInterface, observations: obs_array, total_results: 123) }
    let(:ss_import) { instance_double(SubjectSetImport, id: 1, update_columns: true, save_imported_row_count: true) }
    let(:importer_double) do
      instance_double(Inaturalist::SubjectImporter, import: true, subject_set_import: ss_import)
    end
    let(:count_worker_double) do
      instance_double(SubjectSetSubjectCounterWorker, perform: true)
    end

    context 'when the import is successful' do
      before do
        allow(Inaturalist::SubjectImporter).to receive(:new).and_return(importer_double)
        allow(Inaturalist::ApiInterface).to receive(:new).and_return(api_double)
        allow(SubjectSetImport).to receive(:new).and_return(ss_import)
        allow(SubjectSetSubjectCounterWorker).to receive(:new).and_return(count_worker_double)
        allow(InatImportCompletedMailerWorker).to receive(:perform_async)
      end

      it 'runs SubjectImporter#import on each observation in an enumerable' do
        described_class.new.perform(1, 1, 1)
        expect(importer_double).to have_received(:import).with(obs_array[0])
        expect(importer_double).to have_received(:import).with(obs_array[1])
      end

      it 'calls the subject set import mailer worker' do
        described_class.new.perform(1, 1, 1)
        expect(InatImportCompletedMailerWorker).to have_received(:perform_async).with(ss_import.id)
      end

      it 'calls the subject set counter worker inline' do
        described_class.new.perform(1, 1, 1)
        expect(count_worker_double).to have_received(:perform).with(1)
      end
    end

    context 'when a subject fails to import' do
      let(:taxon_id) { 12345 }
      let(:user) { create(:user) }
      let(:subject_set) { create(:subject_set) }

      before do
        allow(Inaturalist::ApiInterface).to receive(:new).and_return(api_double)
        allow_any_instance_of(Inaturalist::SubjectImporter).to receive(:import).and_raise(Inaturalist::SubjectImporter::FailedImport)
        allow(obs_array[0]).to receive(:external_id).and_return('123asdf')
        allow(obs_array[1]).to receive(:external_id).and_return('456ghj')
      end

      it 'continues processing' do
        expect { described_class.new.perform(user.id, taxon_id, subject_set.id) }.not_to raise_error
      end

      it 'stores the failed count' do
       described_class.new.perform(user.id, taxon_id, subject_set.id)
       expect(SubjectSetImport.where(user_id: user.id, subject_set_id: subject_set.id).first.failed_count).to eq(2)
      end

      it 'stores the failed UUIDs' do
        described_class.new.perform(user.id, taxon_id, subject_set.id)
        expect(SubjectSetImport.where(user_id: user.id, subject_set_id: subject_set.id).first.failed_uuids).to match_array(['123asdf', '456ghj'])
      end
    end
  end
end
