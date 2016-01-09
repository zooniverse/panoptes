require 'spec_helper'

RSpec.describe ReloadCellectWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }

  it "should be retryable 3 times" do
    retry_count = worker.class.get_sidekiq_options['retry']
    expect(retry_count).to eq(3)
  end

  describe "#perform" do

    it "should gracefully handle a missing workflow lookup" do
      expect{worker.perform(-1)}.not_to raise_error
    end

    context "when cellect is off" do
      it "should not call cellect" do
        expect(Subjects::CellectClient).not_to receive(:reload_workflow)
        worker.perform(workflow.id)
      end
    end

    context "when cellect is on" do
      before do
        allow(Panoptes).to receive(:cellect_on).and_return(true)
      end

      it "should not call to cellect if the workflow is not set to use it" do
        expect(Subjects::CellectClient).not_to receive(:reload_workflow)
        worker.perform(workflow.id)
      end

      context "when the workflow is using cellect" do
        before do
          allow_any_instance_of(Workflow)
          .to receive(:using_cellect?).and_return(true)
        end

        it "should request that cellect reload it's workflow" do
          expect(Subjects::CellectClient).to receive(:reload_workflow)
            .with(workflow.id)
          worker.perform(workflow.id)
        end
      end
    end
  end
end
