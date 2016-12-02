require 'spec_helper'

describe CollectionSerializer do
  let(:collection) { create(:collection_with_subjects) }

  describe "::btm_associations" do
    it "should be overriden" do
      expected = [ Collection.reflect_on_association(:projects) ]
      expect(CollectionSerializer.btm_associations).to match_array(expected)
    end
  end

  it "should not have the :projects side load include setup" do
    expect(CollectionSerializer.can_includes).not_to include(:projects)
  end

  it "should preload the serialized associations" do
    expect_any_instance_of(Collection::ActiveRecord_Relation)
      .to receive(:preload)
      .with(*CollectionSerializer::PRELOADS)
      .and_call_original
    CollectionSerializer.page({}, Collection.all, {})
  end
end
