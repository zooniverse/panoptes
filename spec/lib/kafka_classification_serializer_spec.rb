require 'spec_helper'

describe KafkaClassificationSerializer do
  let(:classification) { create(:classification) }
  let(:serializer) { KafkaClassificationSerializer.new(Classification.find(classification.id)) }
  let(:adapter) { Serialization::V1Adapter.new(serializer) }

  it 'can process includes' do
    subject = create(:subject)
    classification.subject_ids = [subject.id]
    adapter = described_class.serialize(classification, include: ['subjects'])
    expect(adapter.as_json[:linked]['subjects'].size).to eq(1)
  end
end
