# frozen_string_literal: true

require 'spec_helper'

describe SubjectGroup, type: :model do
  let(:subject_group) { build(:subject_group) }

  it 'has a valid factory' do
    expect(subject_group).to be_valid
  end

  it 'is invalid without a project_id', :focus do
    subject_group.project = nil
    expect(subject_group).to be_invalid
  end

  describe '#subjects' do
    let(:subject_in_group) { create(:subject) }
    let(:subject_group) do
      build(:subject_group, subjects: [subject_in_group])
    end

    it 'has many subjects' do
      expect(subject_group.subjects).to match_array([subject_in_group])
    end

    it 'is not valid without subjects' do
      subject_group.subjects = []
      expect(subject_group).to be_invalid
    end
  end

  describe '#destroy' do
    let(:subject_group) { create(:subject_group) }
    let(:members) { subject_group.members }
    let(:subjects) { subject_group.subjects }

    before do
      subject_group.destroy
    end

    it 'cleans up the group member records' do
      expect(members.map(:reload)).to match_array([nil])
    end

    it 'is leaves the subjects intact' do
      expect(subjects).to be_valid
    end
  end
end
