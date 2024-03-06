# frozen_string_literal: true

require "spec_helper"

RSpec.describe AggregationClient do
  describe "#send_aggregation_request" do
    before do
      allow(described_class).to receive(:host).and_return("http://test.example.com")
    end

    let(:headers) { { 'Content-Type': 'application/json', 'Accept': 'application/json' } }
    let(:params) { { project_id: 1, workflow_id: 10, user_id: 100 } }
    let(:body) { { task_id: '1234-asdf-1234'} }
    let(:path) { '/run_aggregation' }

    it 'was successful' do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(path, params.to_json, headers) do
          [200, { 'Content-Type':  'application/json' }, body.to_json]
        end
      end

      response = described_class.new([:test, stubs]).send_aggregation_request(1, 10, 100)
      expect(response).to eq(body.with_indifferent_access)
    end

    context 'when there is a problem' do
      describe 'handles server errors' do
        it 'raises if it cannot connect' do
          stubs = Faraday::Adapter::Test::Stubs.new do |stub|
            stub.post(path, params.to_json, headers) do
              raise Faraday::ConnectionFailed, 'execution expired'
            end
          end

          expect do
            described_class.new([:test, stubs]).send_aggregation_request(1, 10, 100)
          end.to raise_error(AggregationClient::ConnectionError)
        end

        it 'raises if it receives a 500' do
          stubs = Faraday::Adapter::Test::Stubs.new do |stub|
            stub.post(path, params.to_json, headers) do
              [
                500,
                { 'Content-Type':  'application/json' },
                { 'errors' => { 'detail' => 'Server internal error' } }.to_json
              ]
            end
          end

          expect do
            described_class.new([:test, stubs]).send_aggregation_request(1, 10, 100)
          end.to raise_error(AggregationClient::ServerError)
        end

        it 'raises if it times out' do
          stubs = Faraday::Adapter::Test::Stubs.new do |stub|
            stub.post(path, params.to_json, headers) do
              raise Faraday::TimeoutError
            end
          end

          expect do
            described_class.new([:test, stubs]).send_aggregation_request(1, 10, 100)
          end.to raise_error(AggregationClient::ConnectionError)
        end

        it 'raises if response is an HTTP 404' do
          stubs = Faraday::Adapter::Test::Stubs.new do |stub|
            stub.post(path, params.to_json, headers) do
              [
                404,
                { 'Content-Type' => 'application/json' },
                { 'errors' => 'Not Found' }.to_json
              ]
            end
          end

          expect do
            described_class.new([:test, stubs]).send_aggregation_request(1, 10, 100)
          end.to raise_error(AggregationClient::ResourceNotFound)
        end
      end
    end
  end
end
