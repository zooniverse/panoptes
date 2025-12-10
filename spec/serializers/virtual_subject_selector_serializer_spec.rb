# frozen_string_literal: true

require 'spec_helper'

describe VirtualSubjectSelectorSerializer do
  let!(:s1) { create(:subject, :with_mediums, num_media: 1) }
  let!(:s2) { create(:subject, :with_mediums, num_media: 1) }
  let(:virtual_subject1) { VirtualSubject.from_member_subjects([s1], virtual_id: -1) }
  let(:virtual_subject2) { VirtualSubject.from_member_subjects([s2], virtual_id: -2) }

  let(:selection_context) do
    {
      select_context: true,
      retired_subject_ids: [],
      user_seen_subject_ids: [],
      favorite_subject_ids: [],
      finished_workflow: false,
      user_has_finished_workflow: false,
      selection_state: :normal,
      selected_at: Time.now.utc
     }
  end

  describe '.page' do
    it 'serializes an array of virtual subjects under subjects key' do
      result = described_class.page({}, [virtual_subject1], selection_context)
      expect(result[:subjects]).to be_an(Array)
      expect(result[:subjects].size).to eq(1)
      expect(result[:subjects].first[:id]).to eq(virtual_subject1.id.to_s)
    end

    it 'includes locations from ordered_locations' do
      result = described_class.page({}, [virtual_subject1], selection_context)
      locs = result[:subjects].first[:locations]
      expect(locs).to all(be_a(Hash))
      expect(locs.map { |h| h.values.first }).to all(be_a(String))
    end

    it 'honors page_size and page parameters' do
      result = described_class.page({ page_size: 1 }, [virtual_subject1, virtual_subject2], selection_context)
      expect(result[:subjects].map { |s| s[:id] }).to eq([virtual_subject1.id.to_s])

      result2 = described_class.page({ page_size: 1, page: 2 }, [virtual_subject1, virtual_subject2], selection_context)
      expect(result2[:subjects].map { |s| s[:id] }).to eq([virtual_subject2.id.to_s])
    end

    it 'includes selection context fields' do
      result = described_class.page({}, [virtual_subject1], selection_context)
      first = result[:subjects].first
      expect(first[:selected_at]).to eq(selection_context[:selected_at])
      expect(first).to have_key(:finished_workflow)
      expect(first).to have_key(:user_has_finished_workflow)
      expect(first).to have_key(:selection_state)
    end
  end
end
