RSpec.shared_examples 'it has ordered locations' do

  it "should sort the loaded locations by index" do
    expected = resource.locations.sort_by { |loc| loc.metadata["index"] }
    expect(expected.map(&:id)).to eq(resource.ordered_locations.map(&:id))
  end

  it "should sort the non-loaded locations by db index" do
    lone_resource = klass.find(resource.id)
    expect_any_instance_of(Medium.const_get('ActiveRecord_Associations_CollectionProxy'))
      .to receive(:order)
      .with("\"media\".\"metadata\"->'index' ASC")
      .and_call_original
    expected = resource.locations.sort_by { |loc| loc.metadata["index"] }
    expect(expected.map(&:id)).to eq(lone_resource.ordered_locations.map(&:id))
  end

  context "resource without location metadata" do
    before do
      resource.locations.update_all(metadata: nil)
      resource.locations
    end

    it "should mimic the database order by using the relation ordering" do
      expected = resource.locations.order("\"media\".\"metadata\"->'index' ASC")
      expect(expected.map(&:id)).to eq(resource.ordered_locations.map(&:id))
    end
  end
end
