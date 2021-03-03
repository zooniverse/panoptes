# frozen_string_literal: true

require 'spec_helper'

describe Subjects::SelectionByIds do
  let(:user) { ApiUser.new(nil) }
  let(:operation_params) do
    { workflow_id: 1, ids: '1,2,3' }
  end
  let(:result) { described_class.run(operation_params).result }

  it 'validates ids param' do
    outcome = described_class.run(operation_params.merge(ids: 'invalid'))
    expect(outcome.errors.full_messages).to include('Ids must be a comma seperated list of digits (max 10)')
  end

  it 'validates ids param contains digits' do
    outcome = described_class.run(operation_params.merge(ids: '1,b'))
    expect(outcome.errors.full_messages).to include('Ids must be a comma seperated list of digits (max 10)')
  end

  it 'validates ids param does not exceed 10 ids' do
    outcome = described_class.run(operation_params.merge(ids: '1,2,3,4,5,6,7,8,9,10,11'))
    expect(outcome.errors.full_messages).to include('Ids must be a comma seperated list of digits (max 10)')
  end

  context 'with subjects that belong to the workflow' do
    let(:workflow) { create(:workflow_with_subject_sets) }
    let(:subject_set) { workflow.subject_sets.first }
    let(:sms) { create_list(:set_member_subject, 2, subject_set: subject_set) }
    let(:subject_ids) { sms.map(&:subject_id).map(&:to_s) }
    let(:operation_params) do
      { workflow_id: workflow.id, ids: subject_ids.join(',') }
    end

    it 'returns the subjects scope in order' do
      expect(result).to eq(subject_ids)
    end

    context 'when subject ids do not belong to the workflow' do
      let(:another_workflow) { create(:workflow, project: workflow.project) }
      let(:operation_params) do
        { workflow_id: another_workflow.id, ids: subject_ids.join(',') }
      end

      it 'raises with error' do
        expect {
          described_class.run!(operation_params)
        }.to raise_error(Operation::Error, 'Supplied subject ids do not belong to the workflow')
      end
    end

    context 'when subject ids are in multiple sets for the workflow' do
      let(:another_set) { create(:subject_set, workflows: [workflow], project: workflow.project) }
      let(:subject_in_mulitple_sets) { sms.first.subject }

      it 'does not raise with error' do
        create(:set_member_subject, subject_set: another_set, subject: subject_in_mulitple_sets)
        expect {
          described_class.run!(operation_params)
        }.not_to raise_error
      end
    end
  end
end
