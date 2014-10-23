require 'spec_helper'

RSpec.describe MultiKafkaProducer::AbstractAdapter do
  subject do
    Class.new(MultiKafkaProducer::AbstractAdapter)
  end
  
  describe "::adapter_name" do
    context "when invoked with a name" do
      it 'should set the name of the adapter' do
        subject.adapter_name :test_adapter
        expect(subject.instance_variable_get(:@name)).to eq(:test_adapter)
      end
    end

    context "when not invoked with a name" do
      it 'should return the adapter name' do
        subject.adapter_name :test_adapter
        expect(subject.adapter_name).to eq(:test_adapter)
      end
    end
  end

  describe "::split_msg_pair" do
    context 'when passed a string' do
      it 'should return an array with nil as its first value' do
        expect(subject.split_msg_pair("asdf").first).to be_nil
      end

      it 'should return the string as the second value' do
        expect(subject.split_msg_pair("asdf")[1]).to eq('asdf')
      end
    end

    context "when passed an array pair" do
      it 'should return the pair' do
        expect(subject.split_msg_pair(["asdf", "asdf"])).to eq(["asdf", "asdf"])
      end
    end
  end
end
