# frozen_string_literal: true

require 'spec_helper'

describe SubjectSetCopier do
  let(:subject_set) { create(:subject_set) }
  let(:project) { subject_set.project }

  describe '.duplicate_subject_set_and_subjects', :focus do
    let(:copied_subject_set) do
      described_class.new(subject_set, project.id).duplicate_subject_set_and_subjects
    end

    it 'copies the name over' do
      expect(copied_subject_set.display_name).to eq(subject_set.display_name)
    end

    it 'is a new id in the db' do
      expect(copied_subject_set.id).not_to eq(subject_set.id)
    end

    it 'has the same number of sms records' do
      expect(copied_subject_set.set_member_subjects.count).not_to eq(subject_set.set_member_subjects.count)
    end

    it 'has the same set_member_subjects_count' do
      expect(copied_subject_set.set_member_subjects_count).to eq(subject_set.set_member_subjects_count)
    end
  end
end