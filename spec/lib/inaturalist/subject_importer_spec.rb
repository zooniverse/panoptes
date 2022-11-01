# frozen_string_literal: true

require 'spec_helper'

describe Inaturalist::SubjectImporter do
  describe '#import' do
    let(:response) { JSON.parse(file_fixture('inat_observations.json').read) }
    let(:obs) { Inaturalist::Observation.new(response['results'][0]) }
    let(:subject_set) { create(:subject_set) }
    let(:importer) { described_class.new(subject_set.project.owner.id, subject_set.id) }
    let(:locations) {
      [
        { 'image/jpeg' => 'https://static.inaturalist.org/photos/12345/original.JPG' },
        { 'image/jpeg' => 'https://static.inaturalist.org/photos/45678/original.JPG' }
      ]
    }

    before { @new_subject = importer.import(obs) }
    # before { let!(:new_subject) { importer.import(obs) } }

    it 'imports new subjects' do
      expect(subject_set.subjects.count).to eq(1)
    end

    it 'sets metadata correctly' do
      expect(subject_set.subjects.first.metadata).to eq(obs.metadata)
    end

    describe 'imported locations' do
      let(:imported_locations) { subject_set.subjects.first.locations.order(:id) }

      it 'sets external_link correctly' do
        expect(imported_locations.map(&:external_link)).to match_array([true, true])
      end

      it 'sets content_type correctly' do
        expect(imported_locations.map(&:content_type)).to match_array(['image/jpeg', 'image/jpeg'])
      end

      it 'sets src correctly' do
        expect(imported_locations[0].src).to eq(locations[0]['image/jpeg'])
        expect(imported_locations[1].src).to eq(locations[1]['image/jpeg'])
      end
    end

    context 'when a record fails to save!' do
      let(:subject_double) { Subject.new }

      before do
        allow(subject_double).to receive(:save!).and_raise(ActiveRecord::RecordInvalid, subject_double)
        allow(importer).to receive(:find_or_initialize_subject).and_return(subject_double)
      end

      it 'raises a relevant error' do
        expect { importer.import(obs) }.to raise_error(Inaturalist::SubjectImporter::FailedImport)
      end
    end

    context 'when a required record does not exist' do
      it 'requires a valid user id' do
        expect { described_class.new(1234, subject_set.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'requires a valid subject_set id' do
        expect { described_class.new(subject_set.project.owner.id, 999999) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when an upsert is required' do
      before do
        # First import is in before block, override with new metadata
        allow(obs).to receive(:metadata).and_return({ 'completely' => 'different' })
        # Reimport with new metadata
        @same_subject = importer.import(obs)
      end

      it 'finds the existing subject' do
        expect(@new_subject.id).to eq(@same_subject.id)
      end

      it 'updates the metadata' do
        expect(@same_subject.metadata).to eq({ 'completely' => 'different' })
      end
    end
  end
end
