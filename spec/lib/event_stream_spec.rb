require 'spec_helper'

describe EventStream do
  before { allow(MultiKafkaProducer).to receive(:publish) }

  it 'pushes events into kafka events topic with custom metadata' do
    EventStream.push('nosepicking', user_id: 1)
    expect(MultiKafkaProducer).to have_received(:publish).with('events',
      [including("panoptes.nosepicking."), including('"user_id":1')]).once
  end

  it 'uses a custom event id' do
    EventStream.push('nosepicking', event_id: 1)
    expect(MultiKafkaProducer).to have_received(:publish).with('events',
      ["panoptes.nosepicking.1", anything]).once
  end

  it 'uses a custom event time' do
    EventStream.push('nosepicking', event_time: Date.new(2015, 1, 2))
    expect(MultiKafkaProducer).to have_received(:publish).with('events',
      [anything, including("2015-01-02")]).once
  end
end
