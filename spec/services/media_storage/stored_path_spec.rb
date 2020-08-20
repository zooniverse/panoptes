# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MediaStorage::StoredPath do
  describe '.media_url' do
    let(:url) { 'https://media.storage.domain/path' }
    let(:result) do
      described_class.media_url(url, stored_path)
    end

    context 'with a migrated aws stored path' do
      let(:stored_path) do
        'panoptes-uploads.zooniverse.org/production/user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg'
      end
      let(:expected_url) do
        "#{url}/production/user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg"
      end

      it 'returns a url without the old path prefix' do
        expect(result).not_to include('panoptes-uploads.zooniverse.org/')
      end

      it 'returns the url with our custom domain path prefix' do
        expect(result).to include(url)
      end

      it 'returns the expected url' do
        expect(result).to eq(expected_url)
      end
    end

    context 'with an azure native stored path (no old aws prefixes)' do
      let(:stored_path) { 'production/subject_location/f2eb4dbc-1353-4598-b1f6-3bf9e9a14169.jpeg' }
      let(:expected_url) do
        "#{url}/production/subject_location/f2eb4dbc-1353-4598-b1f6-3bf9e9a14169.jpeg"
      end

      it 'returns the expected url' do
        expect(result).to eq(expected_url)
      end
    end
  end
end
