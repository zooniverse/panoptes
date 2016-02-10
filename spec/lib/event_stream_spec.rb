require 'spec_helper'

describe EventStream do
  describe "::push" do
    let(:topic) { "nosepicking" }
    before { allow(MultiKafkaProducer).to receive(:publish) }

    it 'pushes events into kafka events topic with custom metadata' do
      EventStream.push(topic, user_id: 1)
      expect(MultiKafkaProducer).to have_received(:publish).with('events',
        [including("panoptes.nosepicking."), including('"user_id":1')]).once
    end

    it 'uses a custom event id' do
      EventStream.push(topic, event_id: 1)
      expect(MultiKafkaProducer).to have_received(:publish).with('events',
        ["panoptes.nosepicking.1", anything]).once
    end

    it 'uses a custom event time' do
      EventStream.push(topic, event_time: Date.new(2015, 1, 2))
      expect(MultiKafkaProducer).to have_received(:publish).with('events',
        [anything, including("2015-01-02")]).once
    end

    it 'ensures the event has a consistently formatted time' do
      time = "#{Time.zone.now}"
      expect(EventStream).to receive(:formatted_time).with(time)
      EventStream.push(topic, event_time: time)
    end
  end

  describe "::formatted_time" do
    let(:time) { Time.zone.now }
    let(:time_str) { "#{Time.zone.now}" }
    let(:iso_time_str) { time.iso8601 }

    it "should convert a string input to a standard format" do
      formatted_time = EventStream.formatted_time(time_str)
      expect(formatted_time).to eq(iso_time_str)
    end

    it "should convert a time input to the iso format" do
      formatted_time = EventStream.formatted_time(time)
      expect(formatted_time).to eq(iso_time_str)
    end

    it "should convert a DateTime input to the iso format" do
      date_time = DateTime.now
      formatted_time = EventStream.formatted_time(date_time)
      expect(formatted_time).to eq(date_time.iso8601)
    end

    it "should raise an error with a weird event time string" do
      expect {
        EventStream.formatted_time("invalid")
      }.to raise_error(ArgumentError)
    end

    it "should raise an error with a non-valid time" do
      expect { EventStream.formatted_time(-1) }.to raise_error(TypeError)
    end
  end
end
