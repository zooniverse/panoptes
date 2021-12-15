# frozen_string_literal: true

require 'spec_helper'

describe SubjectSetImport, type: :model do
  let(:user) { create :user }
  let(:project) { create :project, owner: user }
  let(:subject_set) { create :subject_set, project: project }

  let(:source_url) { "https://example.org/file.csv" }
  let(:csv_file) do
    StringIO.new <<~CSV
      external_id,location:1,location:2,metadata:size,metadata:cuteness
      1,https://placekitten.com/200/300.jpg,https://placekitten.com/200/100.jpg,small,cute
      2,https://placekitten.com/400/900.jpg,https://placekitten.com/500/100.jpg,large,cute
    CSV
  end
  let(:subject_set_import) do
    described_class.create(source_url: source_url, subject_set: subject_set, user: user)
  end
  let(:manifest_row_count) { 2 }

  before do
    allow(UrlDownloader).to receive(:stream).with(source_url).and_yield(csv_file)
  end

  it 'imports subjects to the set' do
    subject_set_import.import!(manifest_row_count)
    expect(subject_set.subjects.count).to eq(2)
  end

  it 'stores the count of imported subjects' do
    subject_set_import.import!(manifest_row_count)
    expect(subject_set_import.imported_count).to eq(2)
  end

  # imported_count / manifest_count gives us the progress measure
  it 'correctly records the progress status during import' do
    allow(subject_set_import).to receive(:save_imported_row_count)
    allow(SubjectSetImport::ProgressUpdateCadence).to receive(:calculate).and_return(2)
    subject_set_import.import!(manifest_row_count)
    # twice: once when the progress is mod 2 == 0 and once at the end
    expect(subject_set_import).to have_received(:save_imported_row_count).twice
  end

  context 'when a subject fails to import' do
    before do
      processor_double = instance_double('SubjectSetImport::Processor')
      allow(processor_double).to receive(:import).and_raise(SubjectSetImport::Processor::FailedImport)
      allow(SubjectSetImport::Processor).to receive(:new).and_return(processor_double)
    end

    it 'continues processing' do
      expect { subject_set_import.import!(manifest_row_count) }.not_to raise_error
    end

    it 'stores the failed count' do
      subject_set_import.import!(manifest_row_count)
      expect(subject_set_import.failed_count).to eq(2)
    end

    it 'stores the failed UUIDs' do
      subject_set_import.import!(manifest_row_count)
      expect(subject_set_import.failed_uuids).to match_array(%w[1 2])
    end
  end

  describe SubjectSetImport::ProgressUpdateCadence do
    describe '.calculate' do
      it 'returns the correct update cadence for 0 rows' do
        expect(described_class.calculate(0)).to eq(0)
      end

      it 'returns the correct update cadence for 1 row' do
        expect(described_class.calculate(1)).to eq(5)
      end

      it 'returns the correct update cadence for 10 rows' do
        expect(described_class.calculate(10)).to eq(5)
      end

      it 'returns the correct update cadence for 100 rows' do
        expect(described_class.calculate(100)).to eq(25)
      end

      it 'returns the correct update cadence for 1000 rows' do
        expect(described_class.calculate(1000)).to eq(50)
      end

      it 'returns the correct update cadence for 10000 rows' do
        expect(described_class.calculate(10000)).to eq(250)
      end

      it 'returns the correct update cadence for above 10000 rows' do
        expect(described_class.calculate(10001)).to eq(500)
      end

      it 'returns the correct update cadence for large num of rows' do
        expect(described_class.calculate(100000)).to eq(500)
      end
    end
  end
end
