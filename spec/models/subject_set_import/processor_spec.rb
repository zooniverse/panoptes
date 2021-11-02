# frozen_string_literal: true

require 'spec_helper'

describe SubjectSetImport::Processor do
  let(:subject_set) { create(:subject_set) }
  let(:user) { create(:user) }
  let(:locations) { [{ 'image/jpeg' => 'https://example.org/image.jpg' }] }
  let(:metadata) { { 'a' => 1, 'b' => 2 } }
  let(:processor) { described_class.new(subject_set, user) }
  let(:run_import) do
    processor.import(1, { locations: locations, metadata: metadata })
  end

  it 'imports new subjects' do
    run_import
    expect(subject_set.subjects.count).to eq(1)
  end

  it 'sets metadata correctly' do
    run_import
    expect(subject_set.subjects.first.metadata).to eq(metadata)
  end

  describe 'imported locations' do
    let(:imported_location) { subject_set.subjects.first.locations[0] }

    before { run_import }

    it 'sets external_link correctly' do
      expect(imported_location.external_link).to be_truthy
    end

    it 'sets content_type correctly' do
      expect(imported_location.content_type).to eq('image/jpeg')
    end

    it 'sets src correctly' do
      expect(imported_location.src).to eq(locations[0]['image/jpeg'])
    end
  end

  context 'when a record fails to save!' do
    let(:subject_double) { Subject.new }

    before do
      allow(subject_double).to receive(:save!).and_raise(ActiveRecord::RecordInvalid, subject_double)
      allow(processor).to receive(:find_or_initialize_subject).and_return(subject_double)
    end

    it 'raises a relevant error' do
      expect { run_import }.to raise_error(SubjectSetImport::Processor::FailedImport)
    end
  end
end
