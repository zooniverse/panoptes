require 'spec_helper'

RSpec.describe PublishDataWorker do
  let(:worker) { described_class.new }
  let(:classification) { create(:classification) }

  describe "#perform" do
    let(:expected_topic) { "classifications" }

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

      it "should not publish", :aggregate_failures do
        expect(MultiKafkaProducer).not_to receive(:publish)
        expect(EventStream).not_to receive(:push)
        worker.perform(classification.id)
      end
    end

    describe "internal classification event stream" do
      let(:serialiser_opts) { { include: ['subjects'] } }

      before do
       allow(worker).to receive(:publish_to_event_stream).and_return(nil)
      end

      it "should format the data using the serializer" do
        expect(KafkaClassificationSerializer)
          .to receive(:serialize)
          .with(an_instance_of(Classification), serialiser_opts)
        worker.perform(classification.id)
      end

      it "should publish via kafka" do
        expected_payload = [classification.project.id, an_instance_of(String)]
        expect(MultiKafkaProducer)
          .to receive(:publish)
          .with(expected_topic, expected_payload)
        worker.perform(classification.id)
      end
    end

    describe "public event stream" do
      let(:payload_expectation) do
        a_hash_including(
          event_id: "#{expected_topic.singularize}-#{classification.id}",
          event_time: classification.updated_at,
          classification_id: classification.id,
          project_id: classification.project.id,
          user_id: Digest::SHA1.hexdigest(classification.user_id.to_s),
          _ip_address: classification.user_ip.to_s
        )
      end

      it "should publish via EventStream" do
        expect(EventStream).to receive(:push)
          .with(expected_topic, payload_expectation)
        worker.perform(classification.id)
      end
    end
  end
end
