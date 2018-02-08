require 'spec_helper'

RSpec.describe ProjectClassificationsCountWorker do
  let(:worker) { described_class.new }
  let!(:project) { create(:project) }

  it "should be rate limited with defaults" do
    opts = worker.class.get_sidekiq_options['congestion']
    expect(opts[:interval]).to eq(60)
    expect(opts[:max_in_interval]).to eq(1)
    expect(opts[:min_delay]).to eq(60)
    expect(opts[:reject_with]).to eq(:reschedule)
  end

  describe "#perform" do

    it 'calls the project counter to update the project counts' do
      expect_any_instance_of(ProjectCounter).to receive(:classifications)
      expect_any_instance_of(Project)
        .to receive(:update_column)
        .with(:classifications_count, anything)
        .once
      worker.perform(project.id)
    end
  end
end
