# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MediaStorage::StoredPath do
  describe '.url_from_src', :focus do
    context 'with a migrated aws stored path' do
      let(:stored_path) { 'panoptes-uploads.zooniverse.org/production/user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg' }
      let(:result) { described_class.url_from_src(stored_path) }

      it 'returns a url without the old path prefix' do
        expect(result).not_to include('panoptes-uploads.zooniverse.org/production/')
      end

      it 'returns the url with our custom domain path prefix' do
        expect(result).to include('https://custom-domain.org/')
      end

      it 'returns the expected url' do
        expect(result).to eq('https://custom-domain.org/user_avatar/1e5fc9b5-86f1-4df3-986f-549f02f969a5.jpeg')
      end
    end

    context 'with an azure native stored path (no old aws prefixes)' do
      let(:stored_path) { 'subject_location/f2eb4dbc-1353-4598-b1f6-3bf9e9a14169.jpeg' }
      let(:result) { described_class.url_from_src(stored_path) }

      it 'returns the expected url' do
        expect(result).to eq('https://custom-domain.org/subject_location/f2eb4dbc-1353-4598-b1f6-3bf9e9a14169.jpeg')
      end
    end
  end
end