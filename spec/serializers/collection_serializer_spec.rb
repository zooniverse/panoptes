require 'spec_helper'

describe CollectionSerializer do
  let(:collection) { create(:collection_with_subjects) }

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { collection }
    let(:includes) { [ :owner, :collection_roles, :subjects ] }
    let(:preloads) do
      [
        [ owner: { identity_membership: :user } ],
        :collection_roles,
        :subjects,
        default_subject: :locations
      ]
    end
  end

  it_should_behave_like "a filter has many serializer" do
    let(:resource) { create(:collection_with_subjects) }
    let(:relation) { :subjects }
    let(:next_page_resource) do
      create(:collection, subjects: resource.subjects)
    end
  end

  describe "sorting" do
    before do
      collection
      first_by_name
    end

    let(:first_by_name) do
      create(:collection, display_name: "Aardvarks")
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

  describe "default subject location" do
    let(:subject_with_media) { create(:subject, :with_mediums, num_media: 1) }
    let(:collection) do
      create(:collection) do |col|
        col.subjects = [ subject_with_media ]
        col.default_subject_id = col.subjects.first.id
      end
    end
    let(:serializer_result) do
      CollectionSerializer.single({}, Collection.where(id: collection.id), {})
    end
    let(:media_location) { subject_with_media.ordered_locations.first }

    it "includes the default subject's url" do
      default_subject_src = serializer_result[:default_subject_src]
      expect(default_subject_src).to eq(media_location.get_url)
    end
  end
end
