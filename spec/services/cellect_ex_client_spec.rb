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
      it 'returns subject ids' do
        subject_ids = described_class.new([:test, stubs]).get_subjects(338, 1, nil, 5)
        expect(subject_ids).to eq([1,2,3,4])
      end

      it "raises if response is an HTTP 500" do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get('/api/workflows/338?limit=5&strategy=weighted&user_id=1') do |env|
            [500, {'Content-Type' => 'application/json'}, {"errors"=>{"detail"=>"Server internal error"}}.to_json]
          end
        end

        expect do
          described_class.new([:test, stubs]).get_subjects(338, 1, nil, 5)
        end.to raise_error(CellectExClient::ServerError)
      end
    end
  end
end
