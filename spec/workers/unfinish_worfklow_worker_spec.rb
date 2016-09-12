require 'spec_helper'

RSpec.describe UnfinishWorkflowWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }

  describe "#perform" do
    it "should not do anything if the workflow is not finished" do
      expect { worker.perform(workflow.id) }.not_to change{ workflow.reload.finished_at }
    end

    context "with a finished worklfow" do
      let(:workflow) { create(:workflow, finished_at: DateTime.now) }

      it "should remove the finished flag if the workflow is finished" do
        expect { worker.perform(workflow.id) }.to change{ workflow.reload.finished_at }
      end
    end
  end
end
