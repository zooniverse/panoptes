# frozen_string_literal: true

require 'spec_helper'

describe SubjectGroup, type: :model do
  let(:subject_group) { build(:subject_group) }

  it 'has a valid factory' do
    expect(subject_group).to be_valid
  end

  it 'is invalid without a project_id' do
    subject_group.project = nil
    expect(subject_group).to be_invalid
  end

  it 'is invalid without any subject_group_members' do
    subject_group.subject_group_members = []
    expect(subject_group).to be_invalid
  end

  it 'is invalid without a key' do
    subject_group.key = nil
    expect(subject_group).to be_invalid
  end

  it 'is invalid without a group_subject_id' do
    subject_group.group_subject = nil
    expect(subject_group).to be_invalid
  end

  describe '#subjects' do
    before do
      # force the through assocation to be loaded
      subject_group.save
      subject_group.subjects(true)
    end

    it 'has many subjects' do
      expect(subject_group.subjects).to all(be_a(Subject))
    end
  end

  describe '#destroy' do
    let(:subject_group) { create(:subject_group) }

    it 'cleans up the group member records' do
      members = subject_group.subject_group_members
      subject_group.destroy
      expect(members.map(&:destroyed?)).to all(be true)
    end

    it 'is leaves the subjects intact' do
      # use true to force the assocation load
      test_subjects = subject_group.subjects(true)
      subject_group.destroy
      expect(test_subjects.map(&:destroyed?)).to all(be false)
    end
  end
end
