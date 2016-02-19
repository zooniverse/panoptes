require 'spec_helper'

RSpec.describe PublishClassificationWorker do
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

      it "should not publish" do
        expect(MultiKafkaProducer).not_to receive(:publish)
        worker.perform(classification.id)
      end
    end

    describe "internal classification event stream" do
      let(:serialiser_opts) { { include: ['subjects'] } }

      it "should format the data using the serializer" do
        expect(KafkaClassificationSerializer)
          .to receive(:serialize)
          .with(an_instance_of(Classification), serialiser_opts)
          .and_call_original
        worker.perform(classification.id)
      end

      it "should publish via kafka" do
        expected_payload = [classification.project.id, instance_of(String)]
        expect(MultiKafkaProducer).to receive(:publish).with(expected_topic, expected_payload)
        worker.perform(classification.id)
      end

      it "should publish via kinesis" do
        publisher = class_double("KinesisPublisher").as_stubbed_const
        expect(publisher).to receive(:publish)
          .with("classification", classification.workflow_id, duck_type(:to_json), duck_type(:to_json))
        worker.perform(classification.id)
      end
    end
  end
end
