# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimulateLongJobWorker do
  describe '#perform' do
    let(:worker_instance) { described_class.new }

    it 'calls sleep with the specified duration' do
      allow(worker_instance).to receive(:sleep).with(10)
      worker_instance.perform(10)
      expect(worker_instance).to have_received(:sleep).with(10)
    end
  end
end
