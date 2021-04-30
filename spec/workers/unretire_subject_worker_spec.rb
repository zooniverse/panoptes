# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UnretireSubjectWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:subject1) { workflow.subjects.first }
  let(:sms) { subject.set_member_subject.first }
  let(:set) { sms.subject_set }
  let(:status) { create(:subject_workflow_status, subject: subject1, workflow: workflow, retired_at: 1.day.ago, retirement_reason: 'other') }

  describe '#perform' do
    context 'when subjects are unretireable' do
      it 'sets retired_at to nil' do
        expect { worker.perform(workflow.id, [subject1.id]) }.to change {
          status.reload.retired_at
        }.to(nil)
      end

      it 'sets retirement_reason to nil' do
        expect { worker.perform(workflow.id, [subject1.id]) }.to change {
          status.reload.retirement_reason
        }.to(nil)
      end

      it 'calls RefreshWorkflowStatusWorker with workflow id' do
        allow(RefreshWorkflowStatusWorker).to receive(:perform_async).and_return(true)
        worker.perform(workflow.id, [subject1.id])
        expect(RefreshWorkflowStatusWorker).to have_received(:perform_async).with(workflow.id)
      end

      it 'calls NotifySubjectSelectorOfChangeWorker with workflow id' do
        allow(NotifySubjectSelectorOfChangeWorker).to receive(:perform_async).and_return(true)
        worker.perform(workflow.id, [subject1.id])
        expect(NotifySubjectSelectorOfChangeWorker).to have_received(:perform_async).with(workflow.id)
      end
    end

    it 'handles unknown workflow' do
      expect { worker.perform(-1, [subject1.id]) }.not_to raise_error
    end 

    it 'handles unknown subject id' do
      expect { worker.perform(workflow.id, [-1]) }.not_to raise_error
    end
    
    context 'when unknown workflow' do 
      it 'does not run RefreshWorkflowStatusWorker' do
        expect(RefreshWorkflowStatusWorker).not_to receive(:perform_async)
        worker.perform(-1, [subject1.id])
      end

      it 'does not run NotifySubjectSelectorOfChangeWorker' do
        expect(NotifySubjectSelectorOfChangeWorker).not_to receive(:perform_async)
        worker.perform(-1, [subject1.id])
      end
    end
  end
end
