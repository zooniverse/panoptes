RSpec.shared_examples 'it has ordered locations' do
  it 'sorts the loaded locations by index' do
    expected = resource.locations.sort_by { |loc| loc.metadata['index'] }
    expect(expected.map(&:id)).to eq(resource.ordered_locations.map(&:id))
  end

  it 'sorts the non-loaded locations by db index', :aggregate_failures do
    lone_resource = klass.find(resource.id)
    expected = resource.locations.sort_by { |loc| loc.metadata['index'] }
    allow(lone_resource.locations).to receive(:order).and_call_original
    expect(expected.map(&:id)).to eq(lone_resource.ordered_locations.map(&:id))
    expect(lone_resource.locations).to have_received(:order).with("media.metadata->'index' ASC")
  end

  context 'when the resource has no location metadata' do
    before do
      resource.locations.update_all(metadata: nil)
      resource.locations
    end

    it 'mimics the database order by using the relation ordering' do
      expected = resource.locations.order(Arel.sql("media.metadata->'index' ASC"))
      expect(expected.map(&:id)).to eq(resource.ordered_locations.map(&:id))
    end
  end
end
