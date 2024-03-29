# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectSetCompletenessWorker do
  subject(:worker) { described_class.new }

  let(:fake_wf_id) { '-1' }
  let(:subject_set) do
    create(:subject_set_with_subjects, num_workflows: 1, num_subjects: 2, completeness: { fake_wf_id => 0.8 })
  end
  let(:workflow) { subject_set.workflows.first }
  let(:subject_sets_workflow) { subject_set.subject_sets_workflows.where(workflow_id: workflow.id).first }

  describe '#perform' do
    it 'ignores an unknown subject set' do
      expect { worker.perform(-1, workflow.id) }.not_to raise_error
    end

    it 'ignores an unknown workflow' do
      expect { worker.perform(subject_set.id, -1) }.not_to raise_error
    end

    context 'when there is no retired data for the workflow' do
      it 'stores 0.0 in the subject_set#completeness json store' do
        expect {
          worker.perform(subject_set.id, workflow.id)
        }.to change {
          subject_set.reload.completeness[workflow.id.to_s]
        }.from(nil).to(0.0)
      end
    end

    context 'when half the set is retired for the workflow' do
      let(:counter_double) { instance_double(SubjectSetWorkflowCounter, retired_subjects: 1) }

      before do
        allow(SubjectSetWorkflowCounter).to receive(:new).and_return(counter_double)
      end

      it 'stores 0.5 in the subject_set#completeness json store' do
        expect {
          worker.perform(subject_set.id, workflow.id)
        }.to change {
          subject_set.reload.completeness[workflow.id.to_s]
        }.from(nil).to(0.5)
      end

      it 'stores 0.5 in the linked subject_set_workflows record' do
        expect {
          worker.perform(subject_set.id, workflow.id)
        }.to change {
          subject_sets_workflow.reload.completeness
        }.from(0.0).to(0.5)
      end

      it 'does not clobber existing per workflow completeness data' do
        expect {
          worker.perform(subject_set.id, workflow.id)
        }.not_to change {
          subject_set.reload.completeness[fake_wf_id]
        }
      end
    end

    context 'with more than 100% complete' do
      let(:counter_double) { instance_double(SubjectSetWorkflowCounter, retired_subjects: 10) }

      before do
        allow(SubjectSetWorkflowCounter).to receive(:new).and_return(counter_double)
      end

      it 'clamps the range of completeness to 1.0 (100%)' do
        expect {
          worker.perform(subject_set.id, workflow.id)
        }.to change {
          subject_set.reload.completeness[workflow.id.to_s]
        }.to(1.0)
      end
    end

    context 'with less than 0% complete' do
      let(:counter_double) { instance_double(SubjectSetWorkflowCounter, retired_subjects: -1) }

      before do
        allow(SubjectSetWorkflowCounter).to receive(:new).and_return(counter_double)
      end

      it 'clamps the range of completeness to 0.0 (0%)' do
        expect {
          worker.perform(subject_set.id, workflow.id)
        }.to change {
          subject_set.reload.completeness[workflow.id.to_s]
        }.to(0.0)
      end
    end

    context 'with no subjects in the subject set' do
      let(:subject_set) { create(:subject_set) }

      it 'raises a custom EmptySubjectSet error' do
        expect {
          worker.perform(subject_set.id, workflow.id)
        }.to raise_error(SubjectSetCompletenessWorker::EmptySubjectSet, "No subjets in subject set: #{subject_set.id}")
      end
    end

    context 'when the set is incomplete' do
      it 'does not run the SubjectSets::RunCompletionEvents operation' do
        allow(SubjectSets::RunCompletionEvents).to receive(:with)
        worker.perform(subject_set.id, workflow.id)
        expect(SubjectSets::RunCompletionEvents).not_to have_received(:with)
      end
    end

    context 'when the set is complete' do
      let(:counter_double) { instance_double(SubjectSetWorkflowCounter, retired_subjects: 2) }

      before do
        allow(SubjectSetWorkflowCounter).to receive(:new).and_return(counter_double)
      end

      it 'does run the SubjectSets::RunCompletionEvents operation' do
        operation_double = SubjectSets::RunCompletionEvents.with(subject_set: subject_set, workflow: workflow)
        allow(operation_double).to receive(:run!)
        allow(SubjectSets::RunCompletionEvents).to receive(:with).and_return(operation_double)
        worker.perform(subject_set.id, workflow.id)
        expect(operation_double).to have_received(:run!)
      end
    end

    context 'when the subject set was already complete' do
      let(:counter_double) { instance_double(SubjectSetWorkflowCounter, retired_subjects: 2) }

      before do
        allow(SubjectSetWorkflowCounter).to receive(:new).and_return(counter_double)
        subject_set.update_column(:completeness, { workflow.id.to_s => '1.0' })
      end

      it 'does not run the SubjectSets::RunCompletionEvents operation' do
        allow(SubjectSets::RunCompletionEvents).to receive(:with)
        worker.perform(subject_set.id, workflow.id)
        expect(SubjectSets::RunCompletionEvents).not_to have_received(:with)
      end
    end
  end
end
