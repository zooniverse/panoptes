require 'spec_helper'

RSpec.describe RefreshWorkflowStatusWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }

  describe "#perform" do
    let(:unfinish_worker_double) { double(:peform) }
    before do
      allow(UnfinishWorkflowWorker)
      .to receive(:new)
      .and_return(unfinish_worker_double)
    end

    it "should call a chain of ordered workers" do
      expect(unfinish_worker_double)
        .to receive(:perform)
        .with(workflow.id)
        .ordered
      expect(WorkflowRetiredCountWorker)
        .to receive(:perform_async)
        .with(workflow.id)
        .ordered
      worker.perform(workflow.id)
    end
  end
end
