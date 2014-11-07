require 'spec_helper'

if RUBY_PLATFORM != 'java'
  RSpec.describe MultiKafkaProducer::Poseidon do
    subject do
      MultiKafkaProducer::Poseidon
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
        expect(subject.instance_variable_get(:@connection)).to be_a(Poseidon::Producer)
      end
    end

    describe "::publish" do
      it 'should write a key,msg pair to a topic' do
        subject.connect 'adsf', 'localhost:9092'
        expect_any_instance_of(Poseidon::Producer).to receive(:send_messages)
        subject.publish("topic", [["key", "msg"]])
      end
    end
  end
end
