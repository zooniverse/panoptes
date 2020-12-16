# frozen_string_literal: true

require 'spec_helper'

describe SubjectGroups::Selection do
  let(:workflow) { create(:workflow, configuration: { subject_group: { num_rows: 1, num_columns: 1 } }) }
  let(:user) { ApiUser.new(nil) }
  let(:subject_selector) { Subjects::Selector.new(user, params) }
  let(:params) { { workflow_id: workflow.id.to_s } }
  let(:operation_params) do
    { num_rows: 1, num_columns: 1, params: params, user: user, uploader_id: workflow.owner.id.to_s }
  end
  let(:subject_group) { instance_double(SubjectGroup) }
  let(:created_subject_groups) { [subject_group, subject_group, subject_group] }
  let(:result) { described_class.run(operation_params).result }

  before do
    allow(subject_selector).to receive(:get_subject_ids).and_return([1, 2, 3])
    allow(Subjects::Selector).to receive(:new).and_return(subject_selector)
    allow(SubjectGroups::Create).to receive(:run!).and_return(subject_group)
  end

  it 'validates num_rows and num_columns param' do
    outcome = described_class.run(operation_params.merge(num_rows: 'invalid', num_columns: 'not a number'))
    expect(outcome.errors.full_messages).to include('Num rows is not a valid integer', 'Num columns is not a valid integer')
  end

  it 'validates the num_rows and num_columns do not create a subject groups beyond a threshold' do
    # default max grid size is 5 x 5 (25)
    outcome = described_class.run(operation_params.merge(num_rows: 5, num_columns: 6))
    expect(outcome.errors.full_messages).to include('Grid size must be less than or equal to 25')
  end

  it 'updates the subject selector page_size params for the group size' do
    described_class.run(operation_params)
    expect(Subjects::Selector).to have_received(:new).with(user.user, params.merge(page_size: 3))
  end

  it 'returns three newly created subject_group in the operation result' do
    expect(result.subject_groups).to match_array(created_subject_groups)
  end

  it 'returns the selector in the operation result' do
    expect(result.subject_selector).to eq(subject_selector)
  end

  context 'with an existing SubjectGroup' do
    before do
      allow(SubjectGroup).to receive(:find_by).and_return(subject_group)
    end

    it 'requests subject ids from the Subjects::Selector' do
      result
      expect(subject_selector).to have_received(:get_subject_ids)
    end

    it 're-uses an existing subject_group in the operation result' do
      expect(result.subject_groups).to match_array(created_subject_groups)
    end
  end

  context 'when the num_rows and num_columns params mismatch the workflow config' do
    let(:workflow) { create(:workflow, configuration: { subject_group: { num_rows: 2, num_columns: 1 } }) }

    it 'raises with error' do
      expect {
        described_class.run!(operation_params)
      }.to raise_error(Operation::Error, 'Supplied num_rows and num_colums mismatches the workflow configuration')
    end
  end

  context 'when the num_rows and num_columns are not single digit integers' do
    it 'fails num_rows and returns a useful error message' do
      outcome = described_class.run(operation_params.merge(num_rows: '10', num_columns: '1'))
      expect(outcome.errors.full_messages).to include('Num rows must be less than 10')
    end

    it 'fails num_columns and returns a useful error message' do
      outcome = described_class.run(operation_params.merge(num_rows: '1', num_columns: '11'))
      expect(outcome.errors.full_messages).to include('Num columns must be less than 10')
    end
  end
end
