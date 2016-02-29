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
        expect(ZooStream).not_to receive(:publish)
        worker.perform(classification.id)
      end
    end

    describe "internal classification event stream" do
      let(:serialiser_opts) { { include: ['project', 'workflow', 'workflow_content', 'user', 'subjects'] } }

      it "should format the data using the serializer" do
        expect(EventStreamSerializers::ClassificationSerializer)
          .to receive(:serialize)
          .with(an_instance_of(Classification), serialiser_opts)
          .and_call_original
        worker.perform(classification.id)
      end

      it "should publish via kinesis" do
        publisher = class_double("ZooStream").as_stubbed_const
        expect(publisher).to receive(:publish)
          .with(event: "classification",
                shard_by: classification.workflow_id,
                data: duck_type(:to_json),
                linked: duck_type(:to_json))
        worker.perform(classification.id)
      end
    end
  end
end
