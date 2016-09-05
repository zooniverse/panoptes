require "spec_helper"

RSpec.describe WorkflowRetiredCountWorker do
  subject(:worker) { WorkflowRetiredCountWorker.new }
  let(:workflow) { create(:workflow) }

  describe "#perform" do

    it 'should update the workflow retired count' do
      allow(Workflow).to receive(:find).and_return(workflow)
      expect(workflow)
        .to receive(:update_column)
        .with(:retired_set_member_subjects_count, anything)
      worker.perform(workflow.id)
    end

    it 'should use a workflow counter to do it' do
      counter = instance_double(WorkflowCounter, retired_subjects: 0)
      expect(WorkflowCounter).to receive(:new).with(workflow).and_return(counter)
      worker.perform(workflow.id)
    end
  end
end
