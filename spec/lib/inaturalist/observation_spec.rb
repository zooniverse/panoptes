# frozen_string_literal: true

require 'spec_helper'

describe Inaturalist::Observation do
  let(:response) { JSON.parse(file_fixture('inat_observations.json').read) }
  let(:obs) { described_class.new(response['results'][0]) }
  let(:obs_metadata) {
    {
      id: 123456789,
      change: 'No changes were made to this image.',
      observed_on: '2011-10-01',
      time_observed_at: '2012-11-11T09:04:12-05:00',
      quality_grade: 'research',
      num_identification_agreements: 2,
      num_identification_disagreements: 0,
      location: '11.111,-11.111',
      geoprivacy: nil,
      scientific_name: 'Sciurus carolinensis'
    }
  }
  let(:obs_locations) {
    [
      { 'image/jpeg' => 'https://static.inaturalist.org/photos/12345/original.JPG' },
      { 'image/jpeg' => 'https://static.inaturalist.org/photos/45678/original.JPG' }
    ]
  }

  it 'returns the external ID' do
    expect(obs.external_id).to eq(response['results'][0]['id'])
  end

  it 'returns a hash of transformed metadata' do
    expect(obs.metadata).to eq(obs_metadata.with_indifferent_access)
  end

  it 'returns a set of locations' do
    expect(obs.locations).to eq(obs_locations)
  end

  context 'when the url is invalid' do
    it 'fills with the default' do
      bad_url = 'https://inaturalist-open-data.s3.amazonaws.com/photos/12345/square.'
      expect(obs.mime_type_from_file_extension(bad_url)).to eq('invalid-filetype')
    end
  end

  describe '#all rights reserved?' do
    let(:obs2) { described_class.new(response['results'][1]) }

    it 'returns true when license code is nil' do
      expect(obs.all_rights_reserved?).to be true
    end

    it 'returns false when there is a license code' do
      expect(obs2.all_rights_reserved?).to be false
    end
  end
end
