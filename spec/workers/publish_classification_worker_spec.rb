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
      let(:serialiser_opts) { { include: ['project', 'workflow', 'user', 'subjects'] } }

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
                shard_by: "#{classification.workflow_id}-#{classification.subjects[0].id}-#{classification.subjects[1].id}",
                data: duck_type(:to_json),
                linked: duck_type(:to_json))
        worker.perform(classification.id)
      end
    end

    context 'when a classification payload is greater than 1MB limit' do
      let(:publish_error) do
        Aws::Kinesis::Errors::ValidationException.new(
          Seahorse::Client::RequestContext,
          "1 validation error detected: Value at 'data' failed to satisfy constraint: Member must have length less than or equal to 1048576"
        )
      end

      before do
        allow(ZooStream).to receive(:publish).and_raise(publish_error)
      end

      it 'raises an error if the project id is not in the ignore list' do
        expect { worker.perform(classification.id) }.to raise_error(Aws::Kinesis::Errors::ValidationException)
      end

      it 'does not raise an error if project id is in the ignore list' do
        allow(ENV).to receive(:fetch).with('KINESIS_PAYLOAD_SIZE_ERROR_PROJECT_ID_INGORE_LIST', '').and_return(classification.project_id.to_s)
        expect { worker.perform(classification.id) }.not_to raise_error
      end
    end
  end
end
