require 'spec_helper'

describe Refinements::RangeClamping do
  using described_class

  let(:range) { 2..10 }

  it 'returns the value if it falls inside the range' do
    expect(range.clamp(5)).to eq(5)
  end

  it 'returns the range min if it falls below the min' do
    expect(range.clamp(1)).to eq(2)
  end

  it 'returns the range max if it falls below the max' do
    expect(range.clamp(20)).to eq(10)
  end
end
