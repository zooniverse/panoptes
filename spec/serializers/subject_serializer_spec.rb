require 'spec_helper'

describe OrganizationSerializer do
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
