require 'spec_helper'

describe SubjectSelectorSerializer do
  let(:subject) { create(:subject, :with_subject_sets, num_sets: 1) }
  let!(:collection) do
    create(:collection, owner: subject.project.owner, subjects: [subject])
  end

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { subject }
    let(:includes) { [] }
    let(:preloads) { [ :locations ] }
  end

  it_should_behave_like "a no count serializer" do
    let(:resource) { subject }
  end

  describe "locations" do
    let(:subject) do
      create(:subject, :with_mediums, :with_subject_sets, num_sets: 1)
    end
    let(:result_locs) do
      SubjectSelectorSerializer.single({}, Subject.all, {})[:locations]
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

  context "subject selection" do
    let(:selection_context) { { select_context: true } }
    let(:run_serializer) do
      SubjectSelectorSerializer.single({}, Subject.all, selection_context)
    end

    describe "seen, retired, finished selection contexts" do
      it "should run the lookups if the feature flag is off" do
        expect_any_instance_of(SubjectSelectorSerializer).to receive(:retired)
        expect_any_instance_of(SubjectSelectorSerializer).to receive(:already_seen)
        expect_any_instance_of(SubjectSelectorSerializer).to receive(:finished_workflow)
        expect_any_instance_of(SubjectSelectorSerializer).to receive(:favorite)
        run_serializer
      end

      context "when skip select context lookup feature flag is on" do
        let(:selection_context) { {} }

        it "should not run the lookups if the feature flag is on" do
          expect_any_instance_of(SubjectSelectorSerializer).not_to receive(:retired)
          expect_any_instance_of(SubjectSelectorSerializer).not_to receive(:already_seen)
          expect_any_instance_of(SubjectSelectorSerializer).not_to receive(:finished_workflow)
          expect_any_instance_of(SubjectSelectorSerializer).not_to receive(:favorite)
          run_serializer
        end
      end
    end
  end
end
