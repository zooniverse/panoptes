# frozen_string_literal: true

require 'spec_helper'

describe SubjectGroups::Create do
  let(:project) { create :project }
  let(:user) { project.owner }
  let(:subjects) do
    create_list(:subject, 2, :with_mediums, num_media: 1, project: project, uploader: user)
  end
  let(:subject_ids) { subjects.map(&:id) }
  let(:operation) { described_class.with(api_user: nil) }
  let(:params) { { subject_ids: subject_ids, uploader_id: user.id.to_s, project_id: project.id.to_s, group_size: 2 } }
  let(:created_subject_group) do
    operation.run!(params)
  end

  it 'creates creates a valid subject_group' do
    expect(created_subject_group).to be_valid
  end

  it 'raises with error if it can not find all the subject_ids' do
    params[:subject_ids] = subject_ids | ['-1']
    params[:group_size] = params[:subject_ids].count
    expect {
      operation.run!(params)
    }.to raise_error(Operation::Error, 'Number of found subjects does not match the number of subject_ids')
  end

  it 'raises with error if the number of subject_ids does not match the expected group_size' do
    params[:subject_ids] = subject_ids | ['-1']
    expect {
      operation.run!(params)
    }.to raise_error(Operation::Error, 'Number of subject_ids does not match the group_size')
  end

  it 'raises with error the number of subject_ids is less than 2' do
    params[:subject_ids] = ['-1']
    params[:group_size] = params[:subject_ids].count
    expect {
      operation.run!(params)
    }.to raise_error(ActiveInteraction::InvalidInteractionError, 'Subject ids size must be greater than or equal to 2')
  end

  it 'raises with error if any of the group subjects have more than one linked media location' do
    multi_location_subject = create(:subject, :with_mediums, num_media: 2, project: project, uploader: user)
    params[:subject_ids] = subject_ids | [multi_location_subject.id]
    params[:group_size] = params[:subject_ids].count
    expect {
      operation.run!(params)
    }.to raise_error(Operation::Error, 'Linked subjects can not have more than one media location')
  end

  it 'raises with error if any of the group subjects are missing a linked media location' do
    no_location_subject = create(:subject, project: project, uploader: user)
    multi_location_subject = create(:subject, :with_mediums, num_media: 2, project: project, uploader: user)
    params[:subject_ids] = [no_location_subject.id, multi_location_subject.id]
    params[:group_size] = params[:subject_ids].count
    expect {
      operation.run!(params)
    }.to raise_error(Operation::Error, 'Linked subjects can not have more than one media location')
  end

  it 'sets the subject_group key' do
    expect(created_subject_group.key).to match(subject_ids.join('-'))
  end

  it 'respects the order of the subject_ids in the key' do
    reversed_subject_ids = subject_ids.reverse
    params[:subject_ids] = reversed_subject_ids
    reverse_key_subject_group = operation.run!(params)
    expect(reverse_key_subject_group.key).to match(reversed_subject_ids.join('-'))
  end

  describe 'group_subject' do
    it 'creates the group_subject' do
      subjects
      expect { created_subject_group }.to change(Subject, :count).by(1)
    end

    it 'creates external media locations' do
      group_subject = created_subject_group.group_subject
      external_locations = group_subject.locations.map(&:external_link)
      expect(external_locations).to match_array(Array.new(subjects.size, true))
    end

    it 'uses the MediaStorage service to construct the external media locations' do
      allow(MediaStorage).to receive(:get_path)
      created_subject_group.group_subject
      expect(MediaStorage).to have_received(:get_path).twice
    end

    it 'creates correct media locations' do
      group_subject = created_subject_group.group_subject
      external_locations = group_subject.locations.map(&:src)
      original_locations = subjects.map(&:locations).flatten.map { |loc| "https://#{loc.src}" }
      expect(external_locations).to match_array(original_locations)
    end

    it 'correctly orders the locations based on the original selected subject ids' do
      locations_in_order = subjects.map(&:locations).flatten
      expected_locations = locations_in_order.map { |loc| "https://#{loc.src}" }
      result_locations = created_subject_group.group_subject.ordered_locations.map(&:src)
      expect(result_locations).to match_array(expected_locations)
    end

    it 'tracks the original subject data provenance in the linked locations' do
      locations_in_order = subjects.map(&:locations).flatten
      expected_locations = locations_in_order.map do |loc|
        ["https://#{loc.src}", loc.linked_id]
      end
      # use the subject location medium resource subject id provenance
      # metadata to ensure we are correctly setting up the subject media locations
      # on the dummy subject, if we don't correctly order these media locations
      # we will incorrectly link a subject to the wrong image resource
      # and thus break the downstream classifications via the UI
      result_locations = created_subject_group.group_subject.locations.map do |loc|
        [loc.src, loc.metadata['originating_subject_id']]
      end
      expect(result_locations).to match_array(expected_locations)
    end

    describe 'tracking the subject group info in the group_subject metadata' do
      let(:group_subject) { created_subject_group.group_subject }

      it 'records the subject_group id in hidden metadata attribute' do
        expect(group_subject.metadata['#subject_group_id']).to match(created_subject_group.id)
      end

      it 'records the group subject ids in hidden metadata attribute' do
        expect(group_subject.metadata['#group_subject_ids']).to match(created_subject_group.key)
      end
    end
  end
end
