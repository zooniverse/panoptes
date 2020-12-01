require "spec_helper"

RSpec.describe SubjectGroupSerializer do
  let(:subject_group) { create(:subject_group) }

  it_behaves_like 'a panoptes restpack serializer' do
    let(:resource) { subject_group }
    let(:includes) { %i[group_subject subjects project] }
    let(:preloads) { %i[group_subject subjects project] }
  end

  # hmm - what is the key to this serializer
  # does it include the subjects in the serilized response?
  # I'm not sure we need this right now...
  # longer term maybe but short term i think not
  # I think add it in and the show route (next PR)
  # and then cycle to the interface with the selector services and
  # creation of this 'SubjectGroup'

  describe 'filtering' do
    let(:serialized_result) { described_class.page(filter, SubjectGroup.all) }
    let(:filtered_resources) { serialized_result[:subject_groups] }
    let(:filtered_ids) { filtered_resources.map { |p| p[:id] } }

    before do
      subject_group
    end

    context 'with key' do
      let(:key) { '3-2-1' }
      let(:filter) { { key: key } }

      it 'filters on key' do
        filtered_resource = create(:subject_group, key: key)
        expect(filtered_ids).to match_array([filtered_resource.id.to_s])
      end
    end
  end

  describe 'links' do
    let(:serialized_result) { described_class.resource({}, SubjectGroup.all) }
    let(:group_subject_link_key) { 'subject_groups.group_subject' }
    let(:expected) do
      {
        href: '/subjects/{subject_groups.group_subject}',
        type: :subjects
      }
    end

    it 'has the correct type for the group_subject resource link' do
      link_details = serialized_result.dig(:links, group_subject_link_key)
      expect(link_details).to include(expected)
    end
  end
end
