require "spec_helper"

RSpec.describe DesignatorClient do
  shared_examples "handles server errors" do
    it "raises if designator can't connect" do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.send(http_method, url) do |env|
          raise Faraday::ConnectionFailed.new("execution expired")
        end
      end

      expect do
        described_class.new([:test, stubs]).send(method, *params)
      end.to raise_error(DesignatorClient::GenericError)
    end

    it "raises if designator times out" do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.send(http_method, url) do |env|
          raise Faraday::TimeoutError
        end
      end

      expect do
        described_class.new([:test, stubs]).send(method, *params)
      end.to raise_error(DesignatorClient::GenericError)
    end

    it "raises if response is an HTTP 500" do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.send(http_method, url) do |env|
          [500, {'Content-Type' => 'application/json'}, {"errors"=>{"detail"=>"Server internal error"}}.to_json]
        end
      end

      expect do
        described_class.new([:test, stubs]).send(method, *params)
      end.to raise_error(DesignatorClient::ServerError)
    end
  end

  let(:headers) { {"Content-Type" => "application/json", "Accept" => "application/json"} }

  context "instance methods" do
    before(:each) do
      allow(described_class).to receive(:config_from_file).and_return({host: "http://test.example.com"})
      described_class.load_configuration
    end

    describe "#get_subjects" do
      it 'returns subject ids' do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get('/api/workflows/338?limit=5&user_id=1', headers) do |env|
            [200, {'Content-Type' => 'application/json'}, [1,2,3,4].to_json]
          end
        end

        subject_ids = described_class.new([:test, stubs]).get_subjects(338, 1, nil, 5)
        expect(subject_ids).to eq([1,2,3,4])
      end

      it_behaves_like "handles server errors" do
        let(:method) { :get_subjects }
        let(:params) { [ 338, 1, nil, 5 ] }
        let(:url) { '/api/workflows/338?limit=5&user_id=1' }
        let(:http_method) { :get }
      end
    end

    describe "#reload_workflow" do
      it 'returns a no-content response' do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post('/api/workflows/338/reload', '', headers) do |env|
            [204, {'Content-Type' => 'application/json'}, nil]
          end
        end

        response = described_class.new([:test, stubs]).reload_workflow(338)
        expect(response).to eq(nil)
      end

      it_behaves_like "handles server errors" do
        let(:method) { :reload_workflow }
        let(:params) { 338 }
        let(:url) { '/api/workflows/338/reload' }
        let(:http_method) { :post }
      end
    end

    describe "#remove_subject" do
      it 'returns a no-content response' do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post('/api/workflows/338/remove', {subject_id: 1}.to_json, headers) do |env|
            [204, {'Content-Type' => 'application/json'}, nil]
          end
        end

        response = described_class.new([:test, stubs]).remove_subject(1, 338)
        expect(response).to eq(nil)
      end

      it_behaves_like "handles server errors" do
        let(:method) { :remove_subject }
        let(:params) { [ 1, 338 ] }
        let(:url) { '/api/workflows/338/remove' }
        let(:http_method) { :post }
      end
    end

    describe "#add_seen_subjects" do
      let(:params) do
        { workflow_id: 338, subject_ids: [1,2,3] }
      end
      it 'returns a no-content response' do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.put('/api/users/1/add_seen_subjects', params.to_json, headers) do |env|
            [204, {'Content-Type' => 'application/json'}, nil]
          end
        end

        response = described_class.new([:test, stubs]).add_seen_subjects([1,2,3], 338, 1)
        expect(response).to eq(nil)
      end

      it 'array wraps an integer subject_ids input' do
        single_int_params = params.merge(subject_ids: [1])
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.put('/api/users/1/add_seen_subjects', single_int_params.to_json, headers) do |env|
            [204, {'Content-Type' => 'application/json'}, nil]
          end
        end

        response = described_class.new([:test, stubs]).add_seen_subjects(1, 338, 1)
        expect(response).to eq(nil)
      end

      it_behaves_like "handles server errors" do
        let(:method) { :add_seen_subjects }
        let(:params) { [ [1,2,3], 338, 1] }
        let(:url) { '/api/users/1/add_seen_subjects' }
        let(:http_method) { :put }
      end
    end
  end
end
