require 'spec_helper'

RSpec.describe WorkflowClassificationsCountWorker do
  let(:worker) { described_class.new }
  let!(:project) { create(:project_with_workflows) }
  let(:workflow) { project.workflows.first }
  let(:count) { rand(10) }

  it "should be rate limited with defaults" do
    opts = worker.class.get_sidekiq_options['congestion']
    expect(opts[:interval]).to eq(60)
    expect(opts[:max_in_interval]).to eq(1)
    expect(opts[:min_delay]).to eq(60)
    expect(opts[:reject_with]).to eq(:reschedule)
  end

  describe "#perform" do
    before do
      expect_any_instance_of(WorkflowCounter)
      .to receive(:classifications)
      .and_return(count)
    end

    it 'calls the workflow counter to update the workflow counts' do
      expect_any_instance_of(Workflow)
        .to receive(:update_column)
        .with(:classifications_count, count)
        .once
      worker.perform(workflow.id)
    end

    it 'chain calls project classification count worker' do
      expect(ProjectClassificationsCountWorker)
        .to receive(:perform_async)
        .with(project.id)
      worker.perform(workflow.id)
    end
  end
end
