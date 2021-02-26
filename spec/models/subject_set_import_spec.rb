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
    described_class.new(source_url: source_url, subject_set: subject_set, user: user)
  end

  before do
    allow(UrlDownloader).to receive(:stream).with(source_url).and_yield(csv_file)
    subject_set_import.import!
  end

  it 'imports subjects to the set' do
    expect(subject_set.subjects.count).to eq(2)
  end

  it 'removes the subject_set_import if the set is deleted', :focus do
    # uses FK on delete cascade constraint
    subject_set_import.save
    expect { subject_set.delete }.not_to raise_error
  end
end
