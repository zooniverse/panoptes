describe SubjectSetImport::Processor do
  let(:subject_set) { create :subject_set }
  let(:user) { create :user }

  let(:locations) { [{"image/jpeg" => "https://example.org/image.jpg"}] }
  let(:metadata) { {"a" => 1, "b" => 2} }

  it 'imports new subjects' do
    processor = described_class.new(subject_set, user)
    processor.import(1, {locations: locations, metadata: metadata})

    expect(subject_set.subjects.count).to eq(1)

    expect(subject_set.subjects.first.locations[0].external_link).to be_truthy
    expect(subject_set.subjects.first.locations[0].content_type).to eq("image/jpeg")
    expect(subject_set.subjects.first.locations[0].src).to eq(locations[0]["image/jpeg"])

    expect(subject_set.subjects.first.metadata).to eq(metadata)
  end
end
