require 'spec_helper'

describe SubjectSetSerializer do
  let(:subject_set) { create(:subject_set) }

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { subject_set }
    let(:includes) { %i(project workflows) }
    let(:preloads) { %i(workflows) }
  end

  it_should_behave_like "a filter has many serializer" do
    let(:resource) { subject_set }
    let(:relation) { :workflows }
    let(:next_page_resource) do
      create(:subject_set, workflows: subject_set.workflows)
    end
  end

  describe 'serialized attributes' do
    let(:expected_attributes) do
      %i[id display_name set_member_subjects_count metadata created_at updated_at href completeness]
    end
    let(:serialized_attributes_no_links) do
      result = described_class.single({}, SubjectSet.where(id: subject_set.id), {})
      result.except(:links).keys
    end

    it 'serializes the correct attributes' do
      expect(serialized_attributes_no_links).to match_array(expected_attributes)
    end
  end
end
