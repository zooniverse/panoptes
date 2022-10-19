require 'spec_helper'

describe Inaturalist::Client do
  let(:page_params) { { taxon_id: 1234 } }
  let(:response_body) { file_fixture('inat_observations.json').read }
  let(:parsed_body) { JSON.parse(response_body) }
  let(:url) { 'https://api.inaturalist.org/v1/observations' }

  describe "#get" do
    it 'sends a default request to the iNat API for observations' do
      client = described_class.new
      stub_request(:get, url)
        .to_return(status: 200, body: response_body)
        .with(query: client.default_params.merge(page_params), headers: client.headers)

      response = client.get(page_params)
      expect(response['total_results']).to eq(parsed_body['total_results'])
      expect(response['results'].first['id']).to eq(parsed_body['results'].first['id'])
      expect(response['results'].last['id']).to eq(parsed_body['results'].last['id'])
    end
  end
end
