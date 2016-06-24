require 'spec_helper'

describe CodeExperiment do
  describe 'running experiments' do
    include Scientist
    let(:admin_enabled) { false }
    let(:config) do
      CodeExperimentConfig.create!(
        name: 'test',
        enabled_rate: enabled_rate,
        always_enabled_for_admins: admin_enabled
      )
    end

    before do
      CodeExperiment.raise_on_mismatches = false
      CodeExperiment.always_enabled = false

      allow(CodeExperiment.reporter).to receive(:publish)
      config
      CodeExperimentConfig.reset_cache!
    end

    context "always enabled" do
      let(:enabled_rate) { 1.0 }

      it 'runs multiple times' do
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

    context "zero enabled rate" do
      let(:enabled_rate) { 0.0 }
      let(:run_experiment) do
        CodeExperiment.run "test" do |e|
          e.use { 1 }
          e.try { 2 }
        end
      end

      it 'should not run' do
        run_experiment
        expect(CodeExperiment.reporter).not_to have_received(:publish)
      end

      context "enabled for admin users" do
        let(:admin_enabled) { true }
        let(:user) { nil }
        let(:run_experiment) do
          CodeExperiment.run "test" do |e|
            e.context user: user
            e.use { 1 }
            e.try { 2 }
          end
        end

        it 'should not run without a user context' do
          run_experiment
          expect(CodeExperiment.reporter).not_to have_received(:publish)
        end

        context "with a normal user context" do
          let(:user) { double("User", is_admin?: false) }

          it 'should not run' do
            run_experiment
            expect(CodeExperiment.reporter).not_to have_received(:publish)
          end
        end

        context "with an admin user context" do
          let(:user) { double("User", is_admin?: true) }

          it 'should run' do
            run_experiment
            expect(CodeExperiment.reporter).to have_received(:publish)
          end
        end
      end
    end
  end
end
