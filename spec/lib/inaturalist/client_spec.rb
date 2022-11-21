# frozen_string_literal: true

require 'spec_helper'

describe Inaturalist::Client do
  let(:page_params) { { taxon_id: 1234 } }
  let(:response_body) { file_fixture('inat_observations.json').read }
  let(:parsed_fixture) { JSON.parse(response_body) }
  let(:url) { 'https://api.inaturalist.org/v2/observations' }

  describe '#get' do
    it 'sends a default request to the iNat API for observations' do
      client = described_class.new
      stub_request(:get, url)
        .to_return(status: 200, body: response_body)
        .with(query: client.default_params.merge(page_params), headers: client.headers)

      response = client.get(page_params)
      parsed_response = JSON.parse(response)
      expect(parsed_response['total_results']).to eq(parsed_fixture['total_results'])
      expect(parsed_response['results'].first['id']).to eq(parsed_fixture['results'].first['id'])
      expect(parsed_response['results'].last['id']).to eq(parsed_fixture['results'].last['id'])
    end
  end
end
