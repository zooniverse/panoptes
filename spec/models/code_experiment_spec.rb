require 'spec_helper'

describe CodeExperiment do
  include ActiveSupport::Testing::TimeHelpers

  before do
    described_class.reset_cache!
  end

  describe '#cache_or_create' do
    it 'creates a new record' do
      expect { described_class.cache_or_create('foo') }.to change { described_class.count }.from(0).to(1)
    end

    it 'fetches an existing record' do
      experiment = described_class.create! name: 'foo'
      expect(described_class.cache_or_create('foo')).to eq(experiment)
    end

    it 'does not fetch multiple times within a short period' do
      described_class.cache_or_create('foo')
      described_class.update_all enabled_rate: 1.0 # simulate a change made by another process

      experiment = described_class.cache_or_create('foo')
      expect(experiment.enabled_rate).to eq(0.0)
    end

    it 'updates the cache after a period of time' do
      described_class.cache_or_create('foo')
      described_class.update_all enabled_rate: 1.0 # simulate a change made by another process

      travel_to 10.minutes.from_now do
        experiment = described_class.cache_or_create('foo')
        expect(experiment.enabled_rate).to eq(1.0)
      end
    end

    it 'returns immutable models' do
      experiment = described_class.cache_or_create('foo')
      expect { experiment.update! enabled_rate: 1.0 }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe 'running experiments' do
    include Scientist

    it 'runs multiple times' do
      allow(CodeExperiment.reporter).to receive(:publish)

      CodeExperiment.create! name: 'test', enabled_rate: 1.0

      result1 = science "test" do |e|
        e.use { 1 }
        e.try { 1 }
      end

      result2 = science "test" do |e|
        e.use { 1 }
        e.try { 2 }
      end

      expect(result1).to eq(1)
      expect(result2).to eq(1)
      expect(CodeExperiment.reporter).to have_received(:publish).twice
    end
  end
end
