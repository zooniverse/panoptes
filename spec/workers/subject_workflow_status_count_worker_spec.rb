require 'spec_helper'

RSpec.describe SubjectWorkflowStatusCountWorker do
  let(:worker) { described_class.new }
  let(:sws) { create(:subject_workflow_status) }

  it "should be rate limited with defaults" do
    opts = worker.class.get_sidekiq_options['congestion']
    expect(opts[:interval]).to eq(30)
    expect(opts[:max_in_interval]).to eq(1)
    expect(opts[:min_delay]).to eq(5)
    expect(opts[:reject_with]).to eq(:reschedule)
  end

  describe "#perform" do

    it 'should call the counter to update the classifications_count' do
      expect_any_instance_of(SubjectWorkflowCounter)
        .to receive(:classifications)
      expect_any_instance_of(SubjectWorkflowStatus)
        .to receive(:update_column)
        .with(:classifications_count, anything)
      worker.perform(sws.id)
    end
  end
end
