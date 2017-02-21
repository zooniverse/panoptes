require 'spec_helper'

describe SubjectSerializer do
  let(:subject) { create(:subject, :with_subject_sets, num_sets: 1) }
  let!(:collection) do
    create(:collection, build_projects: false, owner: subject.project.owner, subjects: [subject])
  end

  it "should preload the serialized associations" do
    expect_any_instance_of(Subject::ActiveRecord_Relation)
      .to receive(:preload)
      .with(:locations, :project, :collections, :subject_sets)
      .and_call_original
    SubjectSerializer.page({}, Subject.all, {})
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
