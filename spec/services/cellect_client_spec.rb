require "spec_helper"

RSpec.describe CellectClient do
  let(:cellect_host) { 'example.com' }
  let(:cellect_request) { instance_double(CellectClient::Request) }

  before do
    allow(CellectClient::Request).to receive(:new).and_return(cellect_request)
  end

  describe '::add_seen' do
    it 'calls the method on the cellect client' do
      expect(cellect_request)
        .to receive(:request)
        .with(:put, ['/workflows/1/users/2/add_seen', { subject_id: 4 }])
      described_class.add_seen(1, 2, 4)
    end
  end

  describe '::load_user' do
    it 'calls the method on the cellect client' do
      expect(cellect_request)
        .to receive(:request)
        .with(:post, '/workflows/1/users/2/load')
      described_class.load_user(1, 2)
    end
  end

  describe '::remove_subject' do
    it 'calls the method on the cellect client' do
      expect(cellect_request)
        .to receive(:request)
        .with(:put, ['/workflows/2/remove', {subject_id: 1, group_id: 4}])
      described_class.remove_subject(1, 2, 4)
    end
  end

  describe '::get_subjects' do
    it 'calls the method on the cellect client' do\
      params = { user_id: 2, group_id: nil, limit: 4 }
      expect(cellect_request)
        .to receive(:request)
        .with(:get, ['/workflows/1', params])
      described_class.get_subjects(1, 2, nil, 4)
    end
  end

  describe '::reload_workflow' do
    it 'calls the method on the cellect client' do
      expect(cellect_request)
        .to receive(:request)
        .with(:post, '/workflows/1/reload')
      described_class.reload_workflow(1)
    end
  end
end

RSpec.describe CellectClient::Request do
  let(:host) { 'test.example.com' }
  let(:url) { "https://#{host}" }

  describe '#request' do
    let(:headers) {
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    }

    it 'sends get request to the remote host' do
      path = '/api/path/on/host'
      host_url_path = "#{url}#{path}"
      response_data = [1, 2, 3, 4]
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get(path, headers) do |env|
          [200, {'Content-Type' => 'application/json'}, response_data.to_json]
        end
      end

      result = described_class.new([:test, stubs], url).request(:get, host_url_path)
      expect(result).to eq(response_data)
    end
  end

  describe 'handles server errors' do
    it "raises if it can't connect" do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get(url) do |env|
          raise Faraday::ConnectionFailed.new('execution expired')
        end
      end

      expect do
        described_class.new([:test, stubs], url).request(:get, [])
      end.to raise_error(CellectClient::Request::GenericError)
    end

    it 'raises if it times out' do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(url) do |env|
          raise Faraday::TimeoutError
        end
      end

      expect do
        described_class.new([:test, stubs], url).request(:post, [])
      end.to raise_error(CellectClient::Request::GenericError)
    end

    it 'raises if response is an HTTP 500' do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.put(url) do |env|
          [
            500,
            { 'Content-Type' => 'application/json' },
            { 'errors' => { 'detail' => 'Server internal error' } }.to_json
          ]
        end
      end

      expect do
        described_class.new([:test, stubs], url).request(:put, [])
      end.to raise_error(CellectClient::Request::ServerError)
    end
  end
end
