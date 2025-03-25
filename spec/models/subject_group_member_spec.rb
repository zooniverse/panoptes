# frozen_string_literal: true

require 'spec_helper'

describe SubjectGroupMember, type: :model do
  let(:subject_group_member) { build(:subject_group_member) }

  it 'has a valid factory' do
    expect(subject_group_member).to be_valid
  end

  describe '#subjects' do
    let(:subject_in_group) { build(:subject) }
    let(:subject_group_member) do
      build(:subject_group_member, subject: subject_in_group)
    end

    it 'has a subject' do
      expect(subject_group_member.subject).to eq(subject_in_group)
    end

    it 'is not valid without a subject' do
      subject_group_member.subject = nil
      expect(subject_group_member).to be_invalid
    end
  end

  describe '#subject_group' do
    let(:subject_group) { build(:subject_group) }
    let(:subject_group_member) do
      build(:subject_group_member, subject_group: subject_group)
    end

    it 'has a subject_group' do
      expect(subject_group_member.subject_group).to eq(subject_group)
    end

    context 'without a subject group' do
      before do
        subject_group_member.subject_group = nil
      end

      it 'is not valid' do
        expect(subject_group_member).to be_invalid
      end

      it 'is has the subject_group error message' do
        subject_group_member.valid?
        model_errors = subject_group_member.errors[:subject_group]
        expect(model_errors).to include("can't be blank")
      end
    end
  end

  describe '#project' do
    it 'has a subject' do
      expect(subject_group_member.project).to eq(nil)
    end
  end

  describe '#display_order' do
    it 'has a display_order' do
      expect(subject_group_member.display_order).to be_a(Integer)
    end

    it 'is not valid without a display_order' do
      subject_group_member.display_order = nil
      expect(subject_group_member).to be_invalid
    end
  end
end
