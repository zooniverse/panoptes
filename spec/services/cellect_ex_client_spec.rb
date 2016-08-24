require "spec_helper"

RSpec.describe CellectExClient do
  let(:stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/api/workflows/338?limit=5&strategy=weighted&user_id=1') do |env|
        [200, {'Content-Type' => 'application/json'}, [1,2,3,4].to_json]
      end
    end
  end

  context "instance methods" do
    before(:each) do
      allow(described_class).to receive(:config_from_file).and_return({host: "http://test.example.com"})
      described_class.load_configuration
    end

    describe "#get_subjects" do
      subject{ described_class.new([:test, stubs]).get_subjects(338, 1, nil, 5) }

      it { is_expected.to eq([1,2,3,4]) }
    end
  end
end
