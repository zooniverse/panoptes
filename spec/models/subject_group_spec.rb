require 'spec_helper'

describe SubjectGroup, type: :model, focus: true do
  let(:subject_group) { build(:subject_group) }

  it 'has a valid factory' do
    expect(subject_group).to be_valid
  end

  it 'is invalid without a project_id' do
    subject_group.project = nil
    expect(subject_group).to be_invalid
  end

  describe '#subjects' do
    let(:subject) { create(:subject) }
    let(:subject_group) do
      build(:subject_group, subjects: [subject])
    end

    it 'has many subjects' do
      expect(subject_group.subjects).to match_array([subject])
    end

    it 'is not valid without subjects' do
      subject_group.subjects = []
      expect(subject_group).to be_invalid
    end
  end
end
