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

  it 'is invalid without any members' do
    subject_group.members = []
    expect(subject_group).to be_invalid
  end

  context 'with out of order member records' do
    let(:current_members) { subject_group.members }
    let(:another_member) { build(:subject_group_member, subject_group: subject_group) }
    let(:out_of_order_members) { [another_member] | current_members }
    let(:expected_key) do
      out_of_order_members.sort { |m| m.display_order }.map(&:subject_id).join('-') # rubocop:disable Style/SymbolProc
    end

    before do
      allow(subject_group).to receive(:members).and_return(out_of_order_members)
    end

    describe '#members_in_display_order' do
      it 'respects the display_order of the members' do
        expect(subject_group.members_in_display_order).to match_array(current_members | [another_member])
      end
    end

    describe '#key' do
      it 'sets the key on save' do
        expect { subject_group.save }.to change(subject_group, :key)
      end

      it 'respects the display_order of the members' do
        subject_group.save
        expect(subject_group.key).to match(expected_key)
      end
    end
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
      members = subject_group.members
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

  describe '#group_subject', :focus do
    let(:subject_group) { build(:subject_group) }
    let(:subject) { subject_group.members.first.subject }
    let(:project_id) { subject.project_id }
    let(:upload_user_id) { subject.upload_user_id }

    before do
      allow(ENV).to receive(:fetch).with('SUBJECT_GROUP_PROJECT_ID').and_return(project_id)
      allow(ENV).to receive(:fetch).with('SUBJECT_GROUP_UPLOAD_USER_ID').and_return(upload_user_id)
    end

    it 'creates the group_subject on save' do
      expect { subject_group.save }.to change { subject_group.group_subject }
    end

    it 'creates the group_subject based on the subject data' do
      subject_group.save
      locations_in_order = subject_group.members_in_display_order.map(&:subject).map(&:locations).flatten
      expected_locations = locations_in_order.map { |loc| "https://#{loc.src}" }
      result_locations = subject_group.group_subject&.locations.map(&:src)
      expect(result_locations).to match(expected_locations)
    end
  end
end
