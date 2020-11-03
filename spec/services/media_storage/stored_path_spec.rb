# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MediaStorage::StoredPath do
  let(:url) { 'https://media.storage.domain/path' }

  before do
    allow(Rails)
      .to receive(:env)
      .and_return('production')
  end

  describe '.media_url' do
    let(:result) do
      described_class.media_url(url, stored_path)
    end

    context 'with a migrated aws stored path' do
      let(:stored_path) do
        'panoptes-uploads.zooniverse.org/production/user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg'
      end
      let(:expected_url) do
        "#{url}/user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg"
      end

      it 'returns a url without the old path prefix' do
        expect(result).not_to include('panoptes-uploads.zooniverse.org/')
      end

      it 'returns the url with our custom domain path prefix' do
        expect(result).to include(url)
      end

      it 'returns the url without the env prefix' do
        expect(result).not_to include('/production')
      end

      it 'returns the expected url' do
        expect(result).to eq(expected_url)
      end
    end

    context 'with an azure native stored path (no old aws prefixes)' do
      let(:stored_path) { 'subject_location/f2eb4dbc-1353-4598-b1f6-3bf9e9a14169.jpeg' }
      let(:expected_url) do
        "#{url}/subject_location/f2eb4dbc-1353-4598-b1f6-3bf9e9a14169.jpeg"
      end

      it 'returns the expected url' do
        expect(result).to eq(expected_url)
      end
    end
  end

  describe '.media_path' do
    let(:result) do
      described_class.media_path(stored_path)
    end

    context 'with a migrated aws stored path' do
      let(:stored_path) do
        'panoptes-uploads.zooniverse.org/production/user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg'
      end
      let(:expected_result) do
        '/user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg'
      end

      it 'returns a path without the old domain prefix and env prefix' do
        expect(result).not_to include('panoptes-uploads.zooniverse.org/production')
      end

      it 'returns the expected path' do
        expect(result).to eq(expected_result)
      end
    end

    context 'with with an azure native stored path (no old aws prefixes)' do
      let(:stored_path) { 'subject_location/f2eb4dbc-1353-4598-b1f6-3bf9e9a14169.jpeg' }
      let(:expected_result) { 'subject_location/f2eb4dbc-1353-4598-b1f6-3bf9e9a14169.jpeg' }

      it 'returns the expected path' do
        expect(result).to eq(expected_result)
      end
    end
  end
end
