require 'spec_helper'

describe SubjectSetImport, type: :model do
  let(:user) { create :user }
  let(:project) { create :project, owner: user }
  let(:subject_set) { create :subject_set, project: project }

  let(:source_url) { "https://example.org/file.csv" }
  let(:csv_file) do
    StringIO.new <<~CSV
      id,location:1,location:2,metadata:size,metadata:cuteness
      1,https://placekitten.com/200/300.jpg,https://placekitten.com/200/100.jpg,small,cute
      2,https://placekitten.com/400/900.jpg,https://placekitten.com/500/100.jpg,large,cute
    CSV
  end

  it 'imports subjects' do
    allow(UrlDownloader).to receive(:stream).with(source_url).and_yield(csv_file)
    subject_set_import = SubjectSetImport.new(source_url: source_url, subject_set: subject_set, user: user)
    subject_set_import.import!

    expect(subject_set.subjects.count).to eq(2)
  end
end
