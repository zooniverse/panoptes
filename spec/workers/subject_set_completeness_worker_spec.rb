# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectSetCompletenessWorker do
  subject(:worker) { described_class.new }

  let(:subject_set) { create(:subject_set_with_subjects, num_workflows: 1, num_subjects: 2) }
  let(:workflow) { subject_set.workflows.first }

  describe '#perform', :focus do
    it 'ignores an unknown subject set' do
      expect{ worker.perform(-1, workflow.id) }.not_to raise_error
    end

    it 'ignores an unknown workflow' do
      expect{ worker.perform(subject_set.id, -1) }.not_to raise_error
    end

    # it 'does not clobber existing per workflow completeness data' do
    #   worker.perform(subject_set.id, workflow.id)

    # end

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
    end
  end
end
