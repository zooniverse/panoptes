require 'spec_helper'

describe EventStreamSerializers::SubjectSerializer do
  let(:subject) { create(:subject, :with_mediums) }
  let(:serializer) { described_class.new(subject) }
  let(:adapter) { Serialization::V1Adapter.new(serializer, {}) }

  it 'serializes the subject locations' do
    expected = subject.ordered_locations.map do |loc|
      { "#{loc.content_type}" => loc.url_for_format(:get) }
    end
    expect(adapter.as_json["subjects"][0][:locations]).to eq(expected)
  end
end
