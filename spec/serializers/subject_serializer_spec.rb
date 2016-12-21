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
      scope = Subject.preload(:locations).all
      SubjectSerializer.single({}, scope, {})[:locations]
    end

    it "should use the model ordered locations sort order" do
      expect_any_instance_of(Subject)
        .to receive(:ordered_locations)
        .and_call_original
      result_locs
    end

    it "should serialize the locations into a mime : url hash" do
      # load the association to match the preload in the serializer scope
      subject.locations
      expected = subject.ordered_locations.map do |loc|
        { :"#{loc.content_type}" => loc.url_for_format(:get) }
      end
      expect(expected).to eq(result_locs)
    end
  end

  context "subject selection" do
    let(:selection_context) { { select_context: true } }
    let(:run_serializer) do
      SubjectSerializer.single({}, Subject.all, selection_context)
    end

    describe "seen, retired, finished selection contexts" do
      it "should run the lookups if the feature flag is off" do
        expect_any_instance_of(SubjectSerializer).to receive(:retired)
        expect_any_instance_of(SubjectSerializer).to receive(:already_seen)
        expect_any_instance_of(SubjectSerializer).to receive(:finished_workflow)
        run_serializer
      end

      context "when skip select context lookup feature flag is on" do
        let(:selection_context) { { select_context: false } }

        it "should not run the lookups if the feature flag is on" do
          expect_any_instance_of(SubjectSerializer).not_to receive(:retired)
          expect_any_instance_of(SubjectSerializer).not_to receive(:already_seen)
          expect_any_instance_of(SubjectSerializer).not_to receive(:finished_workflow)
          run_serializer
        end
      end
    end
  end
end
