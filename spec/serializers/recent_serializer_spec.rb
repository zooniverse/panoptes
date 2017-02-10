require 'spec_helper'

describe RecentSerializer do
  let(:context) do
    { type: "user", owner_id: "1" }
  end

  it "should preload the serialized associations" do
    expect_any_instance_of(Recent::ActiveRecord_Relation)
      .to receive(:preload)
      .with(:locations)
      .and_call_original
    RecentSerializer.page({}, Recent.all, context)
  end

  describe "locations" do
    let!(:recent) { create(:recent) }
    let(:result_locs) do
      RecentSerializer.single({}, Recent.all, context)[:locations]
    end

    it "should use the subject ordered locations method" do
      expect_any_instance_of(Recent)
        .to receive(:ordered_locations)
        .and_call_original
      result_locs
    end

    it "should serialize the locations into a mime : url hash" do
      expected = recent.subject.ordered_locations.map do |loc|
        { :"#{loc.content_type}" => loc.url_for_format(:get) }
      end
      expect(expected).to match_array(result_locs)
    end
  end
end
