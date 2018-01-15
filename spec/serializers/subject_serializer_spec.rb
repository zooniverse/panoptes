require 'spec_helper'

describe SubjectSerializer do
  let(:subject) { create(:subject, :with_subject_sets, num_sets: 1) }
  let!(:collection) do
    create(:collection, owner: subject.project.owner, subjects: [subject])
  end

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { subject }
    let(:includes) { %i(project collections subject_sets) }
    let(:preloads) { %i(locations project collections subject_sets) }
  end

  it_should_behave_like "a filter has many serializer" do
    let(:resource) { subject }
    let(:relation) { :subject_sets }
    let(:next_page_resource) do
      create(:subject, subject_sets: subject.subject_sets)
    end
  end

  describe "locations" do
    let(:subject) do
      create(:subject, :with_mediums, :with_subject_sets, num_sets: 1)
    end
    let(:result_locs) do
      SubjectSerializer.single({}, Subject.all, {})[:locations]
    end

    it "should use the model ordered locations sort order" do
      expect_any_instance_of(Subject)
        .to receive(:ordered_locations)
        .and_call_original
      result_locs
    end

    it "should serialize the locations into a mime : url hash" do
      expected = subject.ordered_locations.map do |loc|
        { :"#{loc.content_type}" => loc.url_for_format(:get) }
      end
      expect(expected).to match_array(result_locs)
    end
  end
end
