require 'spec_helper'

RSpec.describe CsvDumps::DumpProcessor do
  let(:formatter) { double("Formatter", headers: false).tap { |f| allow(f).to receive(:to_rows) { |model| [model] } } }
  let(:scope) { [] }
  let(:medium) { instance_double('Medium', put_file_with_retry: true, metadata: {}, save!: true) }
  let(:csv_dump) { double(CsvDump, cleanup!: true, gzip!: true) }
  let(:processor) { described_class.new(formatter, scope, medium, csv_dump) }

  let(:project_file_name) do
    "#{dump_type}_#{project.owner.login}_#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
  end

  it 'exports the csv headers' do
    allow(formatter).to receive(:headers).and_return(%w(a b c))
    expect(csv_dump).to receive(:<<).with(['a', 'b', 'c']).once
    processor.execute
  end

  it "should create a csv file with the correct number of entries" do
    scope << 1
    scope << 2
    expect(csv_dump).to receive(:<<).exactly(2).times
    processor.execute
  end

  it "should compress the csv file" do
    expect(csv_dump).to receive(:gzip!)
    processor.execute
  end

  it 'push the file to an object store' do
    path = double
    allow(csv_dump).to receive(:gzip!).and_return(path)
    allow(medium).to receive(:put_file_with_retry)
    processor.execute
    expect(medium).to have_received(:put_file_with_retry).with(path, compressed: true).once
  end

  it 'cleans up the file after sending to object store' do
    expect(csv_dump).to receive(:cleanup!).once
    processor.execute
  end

  context 'with no rows' do
    it 'exports nothing' do
      expect(csv_dump).not_to receive(:<<)
      processor.execute
    end
  end

  context 'when the dump fails' do
    it "should leave the medium state as it was" do
      allow(formatter).to receive(:headers).and_raise("something")
      expect(medium).not_to receive(:save!)
      expect { processor.execute }.to raise_error("something")
    end
  end
end
