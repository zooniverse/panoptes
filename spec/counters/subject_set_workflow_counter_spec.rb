# frozen_string_literal: true

require 'spec_helper'

describe SubjectSetWorkflowCounter do
  let(:subject_set) { create(:subject_set_with_subjects, num_workflows: 1, num_subjects: 2) }
  let(:workflow) { subject_set.workflows.first }
  let(:counter) { described_class.new(subject_set.id, workflow.id) }

  describe 'retired_subjects' do
    it 'returns 0 if there are none' do
      expect(counter.retired_subjects).to eq(0)
    end

    context 'with retired_subjects' do
      let(:subject_to_retire) { subject_set.subjects.first }

      before do
        SubjectWorkflowStatus.create(
          workflow_id: workflow.id,
          subject_id: subject_to_retire.id,
          retired_at: Time.now.utc
        )
      end

      it 'returns 1' do
        expect(counter.retired_subjects).to eq(1)
      end
    end
  end
end
