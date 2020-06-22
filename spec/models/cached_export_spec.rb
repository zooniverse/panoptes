# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CachedExport, type: :model do
  # add more polymorphic types as we add dump caching for them
  %i[classification].each do |resource_type|
    let(:resource) { create(resource_type) }
    let(:cached_export) { build(:cached_export, resource: resource) }

    it 'has a valid factory with a resource' do
      expect(cached_export).to be_valid
    end

    it 'is invalid without a resource' do
      expect(build(:cached_export, resource: nil)).not_to be_valid
    end

    it 'is invalid without data' do
      cached_export.data = nil
      cached_export.valid?
      expect(cached_export.errors[:data]).to match_array(["can't be blank"])
    end
  end
end
