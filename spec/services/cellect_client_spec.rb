# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CellectClient do
  let(:cellect_host) { 'example.com' }
  let(:cellect_request) { instance_double(CellectClient::Request) }

  before do
    allow(CellectClient::Request).to receive(:new).and_return(cellect_request)
  end

  describe '::host' do
    it 'configures the host through ENV var' do
      host = 'http://cellect.org'
      allow(ENV).to receive(:fetch).and_return(host)
      expect(described_class.host).to eq(host)
    end
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
        .with(:put, ['/workflows/2/remove', { subject_id: 1, group_id: 4 }])
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
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end

    it 'adds connection middleware for json encoding and decoding' do
      middleware = described_class.new.connection.builder.handlers
      expected = [FaradayMiddleware::EncodeJson, FaradayMiddleware::ParseJson]
      expect(middleware).to include(*expected)
    end

    it 'sends get request to the remote host' do
      path = '/api/path/on/host'
      host_url_path = "#{url}#{path}"
      response_data = [1, 2, 3, 4]
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get(path, headers) do
          [200, { 'Content-Type' => 'application/json' }, response_data.to_json]
        end
      end

      result = described_class.new([:test, stubs], url).request(:get, host_url_path)
      expect(result).to eq(response_data)
    end
  end

  describe 'handles server errors' do
    it "raises if it can't connect" do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get(url) do
          raise Faraday::ConnectionFailed, 'execution expired'
        end
      end

      expect do
        described_class.new([:test, stubs], url).request(:get, [])
      end.to raise_error(CellectClient::ConnectionError)
    end

    it 'raises if it times out' do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(url) do
          raise Faraday::TimeoutError
        end
      end

      expect do
        described_class.new([:test, stubs], url).request(:post, [])
      end.to raise_error(CellectClient::ConnectionError)
    end

    it 'raises if response is an HTTP 500' do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.put(url) do
          [
            500,
            { 'Content-Type' => 'application/json' },
            { 'errors' => { 'detail' => 'Server internal error' } }.to_json
          ]
        end
      end

      expect do
        described_class.new([:test, stubs], url).request(:put, [])
      end.to raise_error(CellectClient::ServerError)
    end

    it 'raises if response is an HTTP 404' do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.put(url) do
          [
            404,
            { 'Content-Type' => 'application/json' },
            { 'errors' => 'Not Found' }.to_json
          ]
        end
      end

      expect do
        described_class.new([:test, stubs], url).request(:put, [])
      end.to raise_error(CellectClient::ResourceNotFound)
    end
  end
end
