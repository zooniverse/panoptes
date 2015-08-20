require 'spec_helper'

describe KafkaClassificationSerializer do
  let(:classification) { create(:classification) }
  let(:serializer) { KafkaClassificationSerializer.new(Classification.find(classification.id)) }
  let(:adapter) { Serialization::V1Adapter.new(serializer) }

  it 'is a substitute for ClassificationSerializer' do
    new_json = adapter.to_json
    old_json = ClassificationSerializer.serialize(classification).to_json

    expect(JSON.load(new_json)).to eq(JSON.load(old_json))
  end

  it 'can process includes' do
    subject = create(:subject)
    classification.subject_ids = [subject.id]
    adapter = described_class.serialize(classification, include: ['subjects'])
    expect(adapter.as_json[:linked]['subjects'].size).to eq(1)
  end
end
