require 'spec_helper'

RSpec.describe PublishDataWorker do
  let(:worker) { described_class.new }
  let(:classification) { create(:classification) }

  describe "#perform" do
    let(:expected_topic) { "classifications" }
    let(:workers) do
      [ PublishClassificationWorker, PublishClassificationEventWorker ]
    end

    it "should gracefully handle a missing classification lookup" do
      expect{
        worker.perform(-1)
      }.not_to raise_error
    end

    it "should call the publish workers", :aggregate_failures do
      workers.each do |worker|
        expect(worker).to receive(:perform_async).with(classification.id)
      end
      worker.perform(classification.id)
    end

    context "when classification is incomplete" do
      before do
        allow_any_instance_of(Classification)
        .to receive(:complete?).and_return(false)
      end

      it "should not call the publish workers", :aggregate_failures do
        workers.each do |worker|
          expect(worker).not_to receive(:perform_async)
        end
        worker.perform(classification.id)
      end
    end
  end
end
