require 'spec_helper'

RSpec.describe MultiKafkaProducer::Null do
  describe "::publish" do
    it 'should write a message to the rails logger' do
      expect(Rails.logger).to receive(:info)
        .with("Attempted to publish to topic with message key => msg")
      MultiKafkaProducer::Null.publish("topic", [["key", "msg"]])
    end
  end
end
