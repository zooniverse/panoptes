require 'spec_helper'

if RUBY_PLATFORM == 'java'
  RSpec.describe MultiKafkaProducer::Kafka do
    subject do
      MultiKafkaProducer::Kafka
    end

    describe "::connected?" do
      context "a connection has been established" do
        it 'should be truthy' do
          subject.connect "asdf", "localhost:9092"
          expect(subject).to be_connected
        end
      end

      context "a connection has not been estasblished" do
        it 'should be falsy' do
          subject.instance_variable_set(:@connection, nil)
          expect(subject).to_not be_connected
        end
      end
    end

    describe "::connect" do
      it 'should set @connection to a Kafka Producer' do
        subject.connect 'adsf', 'localhost:9092'
        expect(subject.instance_variable_get(:@connection)).to be_a(Kafka::Producer)
      end
    end

    describe "::publish" do
      it 'should write a key,msg pair to a topic' do
        subject.connect 'adsf', 'localhost:9092'
        expect_any_instance_of(Kafka::Producer).to receive(:send_msg)
                                                    .with("topic", "key", "msg")
        subject.publish("topic", [["key", "msg"]])
      end

      it 'should raise a KafkaNotConnectedException when it cannot send a msg' do
        subject.connect 'adsf', 'localhost:9092'
        allow_any_instance_of(Kafka::Producer).to receive(:send_msg)
                                                   .and_raise(StandardError)
        expect{ subject.publish("topic", [["key", "msg"]]) }.to raise_error(MultiKafkaProducer::KafkaNotConnected)
      end
    end
  end
end
