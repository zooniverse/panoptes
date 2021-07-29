# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectSetCompletenessWorker do
  subject(:worker) { described_class.new }

  let(:subject_set) { create(:subject_set_with_subjects, num_workflows: 1, num_subjects: 2) }
  let(:workflow) { subject_set.workflows.first }

  describe '#perform', :focus do
    it 'ignore an unkonwn subject set' do
      expect{ worker.perform(workflow.id, -1) }.not_to raise_error
    end

    context 'when there is no retired data for the workflow' do
      it 'stores 0.0 in the subject_set#completeness json store' do
        worker.perform(workflow.id, subject_set.id)
        subject_set_workflow_completeness = subject_set.completeness[workflow.id.to_s]
        expect(subject_set_workflow_completeness).to eq(0.0)
      end
    end

    context 'when half the set is retired for the workflow' do
      let(:subject) { subject_set.subjects.first }

      before do
        SubjectWorkflowStatus.create(workflow_id: workflow.id, subject_id: subject.id, retired_at: Time.now.utc)
      end

      it 'stores 0.5 in the subject_set#completeness json store' do
        worker.perform(workflow.id, subject_set.id)
        subject_set_workflow_completeness = subject_set.completeness[workflow.id.to_s]
        expect(subject_set_workflow_completeness).to eq(0.5)
      end
    end
  end
end
