require 'spec_helper'

RSpec.describe SubjectSetsWorkflow do
  let(:ss_w) { create(:subject_sets_workflow) }

  describe "#remove_from_queues" do
    it 'should queue a removal worker' do
      expect(QueueRemovalWorker).to receive(:perform_async)
        .with(ss_w.subject_set.set_member_subjects.pluck(:id), ss_w.workflow_id)
      ss_w.remove_from_queues
    end
  end
end
