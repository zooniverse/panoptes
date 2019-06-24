require "spec_helper"

RSpec.describe WorkflowSubjectsCountWorker do
  subject(:worker) { WorkflowSubjectsCountWorker.new }
  let(:workflow) { create(:workflow) }

  describe "#perform" do

    it 'should update the workflow set member subjects count' do
      allow(Workflow)
        .to receive(:find_without_json_attrs)
        .with(workflow.id)
        .and_return(workflow)
      expect(workflow)
        .to receive(:update_column)
        .with(:set_member_subjects_count, anything)
      worker.perform(workflow.id)
    end

    it 'should use a workflow counter to do it' do
      counter = instance_double(WorkflowCounter, subjects: 0)
      expect(WorkflowCounter).to receive(:new).with(workflow).and_return(counter)
      worker.perform(workflow.id)
    end
  end
end
