require 'spec_helper'

describe EventStreamSerializers::ClassificationSerializer do
  let(:classification) { create(:classification) }
  let(:serializer) { described_class.new(Classification.find(classification.id)) }
  let(:adapter) { Serialization::V1Adapter.new(serializer) }

  it 'can process includes' do
    subject = create(:subject)
    classification.subject_ids = [subject.id]
    adapter = described_class.serialize(classification, include: ['subjects'])
    expect(adapter.as_json[:linked]['subjects'].size).to eq(1)
  end

  describe 'serialize for kinesis stream' do
    it 'follows format of kinesis stream' do
      serialized_data = described_class
                        .serialize(classification, include: %w[project workflow user subjects])
                        .as_json
                        .with_indifferent_access

      sample_kinesis_json = JSON.parse(file_fixture('example_event_stream_serializer_classification.json').read)

      expect(serialized_data.keys).to match_array(%w[classifications linked])
      expect(serialized_data[:classifications][0].keys).to match_array(sample_kinesis_json['data'].keys)
      expect(serialized_data[:linked].keys).to match_array(sample_kinesis_json['linked'].keys)
    end
  end
end
