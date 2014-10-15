require 'spec_helper'

RSpec.describe KafkaEvent do
  let(:test_class) do
    Class.new do
      include KafkaEvent

      kafka_event :event_thing, topic: 'events1',
        attributes: [:id, :name], links: [:subjects, :owner]

      def self.delay
        self
      end

    end
  end

  let(:models) { create_list(:collection_with_subjects, 3) }

  before(:each) do
    allow(MultiKafkaProducer).to receive(:publish)
    allow(test_class).to receive(:find)
      .and_return(models)
  end

  describe "::kafka_event" do
    it 'should create method with the event name' do
      expect(test_class).to respond_to(:event_thing)
    end

    it 'should call delay' do
      expect(test_class).to receive(:delay).and_return(test_class)
      test_class.event_thing(1,2,3)
    end

    it 'should call publish_to_kafka' do
      expect(test_class).to receive(:publish_to_kafka)
        .with('events1', :event_thing, [1, 2, 3])
      test_class.event_thing(1,2,3)
    end
  end

  describe "::publish_to_kafka" do
    it 'should publish to kafka' do
      expect(MultiKafkaProducer).to receive(:publish).exactly(3).times
        .with('events1', ['event_thing', /.*/])
      test_class.publish_to_kafka('events1', :event_thing, [1,2,3])
    end
  end
end
