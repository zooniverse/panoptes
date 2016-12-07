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

  describe "sorting" do
    before do
      collection
      first_by_name
    end

    let(:first_by_name) do
      create(:collection, build_projects: false, display_name: "Aardvarks")
    end
    let(:serialized_page) do
      CollectionSerializer.page({sort: "display_name"}, Collection.all, {})
    end

    describe "by display_name" do
      it 'should respect the sort order query param' do
        results = serialized_page[:collections].map{ |r| r[:display_name] }
        expected = [ first_by_name.display_name, collection.display_name ]
        expect(results).to eq(expected)
      end
    end
  end
end
