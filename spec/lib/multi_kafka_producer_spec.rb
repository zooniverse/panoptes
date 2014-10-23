require 'spec_helper'

shared_examples "default adapter" do
  it 'should set the default adapter for the platform' do
    MultiKafkaProducer.adapter =  nil
    expect(adapter).to be(expected_adapter)
  end
end

shared_examples "loads by name" do
  it 'should try to load the kafka adapter by name' do
    MultiKafkaProducer.adapter = adapter_name
    expect(adapter).to be(expected_adapter)
  end
end

describe MultiKafkaProducer do
  let(:adapter) { MultiKafkaProducer.adapter }
  
  if RUBY_PLATFORM == 'java'
    let(:expected_adapter) { MultiKafkaProducer::Kafka }
  else
    let(:expected_adapter) { MultiKafkaProducer::Poseidon }
  end
  
  describe "::adapter=" do
    context "a string" do
      if RUBY_PLATFORM == 'java'
        let(:adapter_name) { 'kafka' }
      else
        let(:adapter_name) { 'poseidon' }
      end
      
      it_behaves_like "loads by name"
    end

    context "a symbol" do
      if RUBY_PLATFORM == 'java'
        let(:adapter_name) { :kafka }
      else
        let(:adapter_name) { :poseidon }
      end
      
      it_behaves_like "loads by name"
    end

    context "falsy" do
      it_behaves_like "default adapter"
    end

    context "class" do
      it 'should set adapter to the supplied class' do
        klass = Class.new
        MultiKafkaProducer.adapter = klass
        expect(MultiKafkaProducer.adapter).to be(klass)
      end
    end
  end

  describe "::adapter" do
    context "when no adapter has been set" do
      it_behaves_like "default adapter"
    end
  end

  describe "::connect" do
    before(:each) do
      allow(MultiKafkaProducer).to receive(:adapter).and_return(adapter)
    end
    
    let(:adapter) { double({ connected?: true }) }
    
    it 'should call connect on the adapter with the supplied args' do
      expect(adapter).to receive(:connect)
        .with("client-id", "broker1", "broker2")
      MultiKafkaProducer.connect("client-id", "broker1", "broker2")
    end
  end

  describe "::publish" do
    before(:each) do
      allow(MultiKafkaProducer).to receive(:adapter).and_return(adapter)
    end

    context "connected adapter" do
      let(:adapter) { double({ connected?: true }) }
      
      it 'should call publish on the adapter with the supplied args' do
        expect(adapter).to receive(:publish).with('topic', [['key', 'msg']])
        MultiKafkaProducer.publish('topic', ['key', 'msg'])
      end
    end

    context "disconnected adapter" do
      let(:adapter) { double({ connected?: false, adapter_name: "blerg" }) }
      
      it 'should raise an exception when the adapter is not connected' do
        expect do
          MultiKafkaProducer.publish('topic', ['key', 'msg'])
        end.to raise_error(MultiKafkaProducer::KafkaNotConnected)
      end
    end
  end
end
