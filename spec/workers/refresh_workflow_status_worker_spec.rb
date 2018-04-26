require 'spec_helper'

RSpec.describe RefreshWorkflowStatusWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:unfinish_worker_double) { double(:peform) }
  let(:retired_count_worker_double) { double(:peform) }
  let(:completeness_worker_double) { double(:peform) }
  let(:klass_doubles) do
    {
      UnfinishWorkflowWorker => unfinish_worker_double,
      WorkflowRetiredCountWorker => retired_count_worker_double,
      CalculateProjectCompletenessWorker => completeness_worker_double
    }
  end

  describe "#perform" do
    before do
      klass_doubles.each do |klass, double|
        allow(klass)
          .to receive(:new)
          .and_return(double)
      end
    end

    it "should call a chain of ordered workers" do
      expect(unfinish_worker_double)
        .to receive(:perform)
        .with(workflow.id)
        .ordered
      expect(retired_count_worker_double)
        .to receive(:perform)
        .with(workflow.id)
        .ordered
      expect(completeness_worker_double)
        .to receive(:perform)
        .with(workflow.project_id)
        .ordered
      worker.perform(workflow.id)
    end
  end
end
