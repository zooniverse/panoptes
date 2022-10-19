require 'spec_helper'

describe Inaturalist::ApiInterface do

  let(:response) { JSON.parse(file_fixture('inat_observations.json').read) }
  let(:client) { instance_double(Inaturalist::Client) }
  let(:interface) { described_class.new(taxon_id: 46017) }

  context 'enumeration' do
    before do
      allow(Inaturalist::Client).to receive(:new).and_return(client)
      allow(client).to receive(:get).and_return(response)
      allow(interface).to receive(:client).and_return(client)
    end

    it 'behaves like an enumerator' do
      expect(interface.observations).to be_a(Enumerator)
      expect(interface.observations.respond_to?(:each)).to be true
    end

    it 'transforms iNat API response into Observation instances' do
      expect(interface.observations.each.to_a).to match_array([
        have_attributes(
          class: Inaturalist::Observation,
          external_id: 123456789
        ),
        have_attributes(
          class: Inaturalist::Observation,
          external_id: 987654321
        )
      ])
    end
  end

  context 'pagination' do
    let(:page_one) {
      {
        "total_results": 3,
        "page": 1,
        "per_page": 1,
        "results": [response['results'][0]]
      }
    }
    let(:page_two) {
      {
        "total_results": 4,
        "page": 2,
        "per_page": 1,
        "results": [response['results'][1]]
      }
    }
    let(:last_page) {
      {
        "total_results": 5,
        "page": 3,
        "per_page": 1,
        "results": []
      }
    }

    before(:each) do
      allow(Inaturalist::Client).to receive(:new).and_return(client)
      allow(interface).to receive(:client).and_return(client)
      allow(client).to receive(:get).and_return(
        page_one.with_indifferent_access,
        page_two.with_indifferent_access,
        last_page.with_indifferent_access
      )
    end

    it 'paginates and then stops when results are empty' do
      expect(interface.fetch_next_page).to eq([response['results'][0]])
      expect(interface.fetch_next_page).to eq([response['results'][1]])
      expect(interface.fetch_next_page).to eq(response['results'][2])
    end

    it 'stops paginating on id match' do
      interface.instance_variable_set(:@id_above, 123456789)
      expect(interface.fetch_next_page).to eq(nil)
    end

    it 'stops paginating upon reaching MAX_OBSERVATIONS' do
      interface.instance_variable_set(:@max_observations, 1)
      expect(interface.fetch_next_page).to eq([response['results'][0]])
      expect(interface.fetch_next_page).to eq(nil)
    end
  end
end
