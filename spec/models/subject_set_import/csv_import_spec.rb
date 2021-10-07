require 'spec_helper'

describe SubjectSetImport::CsvImport do
  let(:csv_data) do
    <<~CSV
      external_id,location:1,location:2,metadata:size,metadata:cuteness
      1,https://placekitten.com/200/300.jpg,https://placekitten.com/200/100.jpg,small,cute
      2,https://placekitten.com/400/900.jpg,https://placekitten.com/500/100.jpg,large,cute
    CSV
  end
  let(:io) { StringIO.new(csv_data) }
  let(:csv_import) { described_class.new(io) }
  let(:expected_rows) do
    [
      [
        '1',
        {
          locations:
            [
              { 'image/jpeg' => 'https://placekitten.com/200/300.jpg' },
              { 'image/jpeg' => 'https://placekitten.com/200/100.jpg' }
            ],
          metadata: { 'size' => 'small', 'cuteness' => 'cute' }
        }
      ],
      [
        '2',
        {
          locations:
            [
              { 'image/jpeg' => 'https://placekitten.com/400/900.jpg' },
              { 'image/jpeg' => 'https://placekitten.com/500/100.jpg' }
            ],
          metadata: { 'size' => 'large', 'cuteness' => 'cute' }
        }
      ]
    ]
  end

  it 'returns subject IDs and attributes' do
    expect(csv_import.each.to_a).to eq(expected_rows)
  end

  describe '#headers' do
    let(:expected_headers) do
      %w(external_id location:1 location:2 metadata:size metadata:cuteness)
    end

    it 'uses headers' do
      expect(csv_import.headers).to eq(true)
    end

    it 'returns the headers strings after accessing csv data' do
      csv_import.each.to_a
      expect(csv_import.headers).to match_array(expected_headers)
    end
  end
end
