require 'spec_helper'

describe KafkaClassificationSerializer do
  let(:classification) { create(:classification) }

  it 'is a substitute for ClassificationSerializer' do
    serializer = KafkaClassificationSerializer.new(Classification.find(classification.id))
    adapter = Serialization::V1Adapter.new(serializer)

    new_json = adapter.to_json
    old_json = ClassificationSerializer.serialize(classification).to_json

    expect(JSON.load(new_json)).to eq(JSON.load(old_json))
  end
end
