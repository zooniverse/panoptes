require 'spec_helper'

RSpec.describe ReloadCellectWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }

  describe "#perform" do
    context "when cellect is off" do
      it "should return straight away" do
        expect(Subjects::CellectClient).not_to receive(:reload_workflow)
        worker.perform(workflow.id)
      end
    end

    context "when cellect is on" do
      before do
        allow(Panoptes).to receive(:cellect_on).and_return(true)
      end

      it "should request that cellect reload it's workflow" do
        expect(Subjects::CellectClient).to receive(:reload_workflow)
          .with(workflow.id)
        worker.perform(workflow.id)
      end

      context "when cellect is unavailable" do
        it "should handle the failure and move on" do
          allow(Subjects::CellectClient).to receive(:reload_workflow)
            .and_raise(Subjects::CellectClient::ConnectionError)
          expect{worker.perform(workflow.id)}.not_to raise_error
        end
      end
    end
  end
end
