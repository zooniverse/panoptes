# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Formatter::Caching do
  let(:data) { { 'cached_attribute' => 'this is from the cache' } }
  let(:cache_resource) { instance_double('CachedExport', data: data) }
  let(:formatter) do
    double(
      'Formatter',
      cached_attribute: 'this should not be returned',
      non_cached_attribute: 'this is from the formatter'
    )
  end
  let(:caching_formatter) do
    described_class.new(cache_resource, formatter)
  end

  it 'returns the cache resource by default' do
    expect(caching_formatter.cached_attribute).to eq('this is from the cache')
  end

  it 'returns formatter value when no matching attribue in cache resource' do
    expect(caching_formatter.non_cached_attribute).to eq('this is from the formatter')
  end
end
