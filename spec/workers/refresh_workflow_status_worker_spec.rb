require 'spec_helper'

RSpec.describe RefreshWorkflowStatusWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }

  describe "#perform" do
    let(:ordered_worker_instances) do
      [
        UnfinishWorkflowWorker,
        WorkflowRetiredCountWorker,
        CalculateProjectCompletenessWorker
      ].map(&:new)
    end

    before do
      allow(worker)
      .to receive(:ordered_workers)
      .and_return(ordered_worker_instances)
    end

    it "should chain the following workers in this order" do
      ordered_worker_instances[0..1].each do |worker|
        expect(worker).to receive(:perform).with(workflow.id).ordered
      end
      expect(ordered_worker_instances.last)
        .to receive(:perform)
        .with(workflow.project_id)
        .ordered

      worker.perform(workflow.id)
    end
  end
end
