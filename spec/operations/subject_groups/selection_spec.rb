# frozen_string_literal: true

require 'spec_helper'

describe SubjectGroups::Selection do
  let(:workflow) { create(:workflow, configuration: { subject_group: { num_rows: 2, num_columns: 2 } }) }
  let(:user) { ApiUser.new(nil) }
  let(:subject_selector) { Subjects::Selector.new(user, params) }
  let(:params) { { workflow_id: workflow.id.to_s } }
  let(:operation_params) do
    { num_rows: 2, num_columns: 2, params: params, user: user, uploader_id: workflow.owner.id.to_s }
  end
  let(:subject_group) { instance_double(SubjectGroup) }
  let(:outcome) { described_class.run(operation_params) }

  before do
    allow(subject_selector).to receive(:get_subject_ids).and_return([1])
    allow(Subjects::Selector).to receive(:new).and_return(subject_selector)
    allow(SubjectGroups::Create).to receive(:run!).and_return(subject_group)
  end

  it 'handles num_rows and num_columns param validation' do
    outcome = described_class.run(operation_params.merge(num_rows: 'invalid', num_columns: 'not a number'))
    expect(outcome.errors.full_messages).to include('Num rows is not a valid integer', 'Num columns is not a valid integer')
  end

  it 'updates the subject selector page_size params for the group size' do
    described_class.run(operation_params)
    expect(Subjects::Selector).to have_received(:new).with(user.user, params.merge(page_size: 4))
  end

  it 'returns a newly created subject_group in the operation result' do
    expect(outcome.result.subject_group).to eq(subject_group)
  end

  it 'returns the selector in the operation result' do
    expect(outcome.result.subject_selector).to eq(subject_selector)
  end

  context 'with an existing SubjectGroup' do
    before do
      allow(SubjectGroup).to receive(:find_by).and_return(subject_group)
    end

    it 'requests subject ids from the Subjects::Selector' do
      outcome.result
      expect(subject_selector).to have_received(:get_subject_ids)
    end

    it 're-uses an existing subject_group in the operation result' do
      expect(outcome.result.subject_group).to eq(subject_group)
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
end
