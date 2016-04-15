require 'spec_helper'

describe CodeExperiment do
  describe 'running experiments' do
    include Scientist

    it 'runs multiple times' do
      allow(CodeExperiment.reporter).to receive(:publish)

      CodeExperimentConfig.create! name: 'test', enabled_rate: 1.0

      result1 = CodeExperiment.run "test" do |e|
        e.use { 1 }
        e.try { 1 }
      end

      result2 = CodeExperiment.run "test" do |e|
        e.use { 1 }
        e.try { 2 }
      end

      expect(result1).to eq(1)
      expect(result2).to eq(1)
      expect(CodeExperiment.reporter).to have_received(:publish).twice
    end
  end
end
