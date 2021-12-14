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
  let(:num_lines) { 3 }

  before do
    allow(UrlDownloader).to receive(:stream).with(source_url).and_yield(csv_file)
  end

  it 'imports subjects to the set' do
    subject_set_import.import!
    expect(subject_set.subjects.count).to eq(2)
  end

  it 'stores the count of imported subjects' do
    subject_set_import.import!
    expect(subject_set_import.imported_count).to eq(2)
  end

  # imported_count / manifest_count gives us the progress measure
  it 'correctly records the progress status during import'do
    allow(subject_set_import).to receive(:save_imported_row_count)
    subject_set_import.import!(2)
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
      expect { subject_set_import.import! }.not_to raise_error
    end

    it 'stores the failed count' do
      subject_set_import.import!
      expect(subject_set_import.failed_count).to eq(2)
    end

    it 'stores the failed UUIDs' do
      subject_set_import.import!
      expect(subject_set_import.failed_uuids).to match_array(%w[1 2])
    end
  end
end
