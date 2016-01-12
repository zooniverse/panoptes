require 'spec_helper'

RSpec.describe PublishClassificationEventWorker do
  let(:worker) { described_class.new }
  let(:classification) { create(:classification) }

  describe "#perform" do
    it "should gracefully handle a missing classification lookup" do
      expect{
        worker.perform(-1)
      }.not_to raise_error
    end

    context "when classification is incomplete" do
      before do
        allow_any_instance_of(Classification)
        .to receive(:complete?).and_return(false)
      end

      it "should not publish" do
        expect(EventStream).not_to receive(:push)
        worker.perform(classification.id)
      end
    end

    describe "public event stream" do
      let(:payload_expectation) do
        a_hash_including(
          event_id: "classification-#{classification.id}",
          event_time: "#{classification.updated_at}",
          classification_id: classification.id,
          project_id: classification.project.id,
          user_id: Digest::SHA1.hexdigest(classification.user_id.to_s),
          _ip_address: classification.user_ip.to_s
        )
      end

      it "should publish via EventStream" do
        expect(EventStream).to receive(:push)
          .with("classifications", payload_expectation)
        worker.perform(classification.id)
      end
    end
  end
end
