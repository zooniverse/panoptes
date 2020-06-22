RSpec.shared_examples 'a dump processor' do
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

  it "push the file to s3" do
    path = double
    allow(csv_dump).to receive(:gzip!).and_return(path)
    expect(medium).to receive(:put_file).with(path, compressed: true).once
    processor.execute
  end

  it "should clean up the file after sending to s3" do
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
