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
    let(:subject_locs) do
      subject.locations.sort_by { |loc| loc.metadata["index"] }
    end
    let(:result_locs) do
      SubjectSerializer.single({}, Subject.all, {})[:locations]
    end

    it "should sort the related locations index" do
      expected = subject_locs.map { |loc| loc.src.split("/").last }
      results = result_locs.map { |loc| loc[:"image/jpeg"].split("/").last }
      expect(expected).to eq(results)
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
