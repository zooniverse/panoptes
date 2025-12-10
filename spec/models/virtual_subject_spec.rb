# frozen_string_literal: true

require 'spec_helper'

describe VirtualSubject, type: :model do
  let!(:s1) { create(:subject, :with_mediums, num_media: 1) }
  let!(:s2) { create(:subject, :with_mediums, num_media: 2) }

  describe '.from_member_subjects' do
    it 'builds a virtual subject with negative id when not provided' do
      virtual_subject = described_class.from_member_subjects([s1, s2])
      expect(virtual_subject.id).to eq(-1)
    end

    it 'uses the supplied virtual_id when provided' do
      virtual_subject = described_class.from_member_subjects([s1, s2], virtual_id: -1)
      expect(virtual_subject.id).to eq(-1)
    end

    it 'sets metadata with #group_subject_ids key' do
      virtual_subject = described_class.from_member_subjects([s1, s2], virtual_id: -1)
      expect(virtual_subject.metadata['#group_subject_ids']).to eq("#{s1.id}-#{s2.id}")
    end

    it 'flattens member media into ordered_locations' do
      virtual_subject = described_class.from_member_subjects([s1, s2], virtual_id: -1)
      expect(virtual_subject.ordered_locations.length).to eq(s1.ordered_locations.length + s2.ordered_locations.length)
    end
  end
end

