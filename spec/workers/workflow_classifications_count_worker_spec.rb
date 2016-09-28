require 'spec_helper'

RSpec.describe WorkflowClassificationsCountWorker do
  let(:worker) { described_class.new }
  let!(:project) { create(:project_with_workflows) }
  let(:workflow) { project.workflows.first }
  let(:count) { rand(10) }

  describe "#perform" do
    before do
      expect_any_instance_of(WorkflowCounter)
      .to receive(:classifications)
      .and_return(count)
    end

    it 'calls the workflow counter to update the workflow counts' do
      expect_any_instance_of(Workflow)
        .to receive(:update_column)
        .with(:classifications_count, count)
        .once
      worker.perform(workflow.id)
    end

    it 'chain calls project classification count worker' do
      expect(ProjectClassificationsCountWorker)
        .to receive(:perform_async)
        .with(project.id)
      worker.perform(workflow.id)
    end
  end
end
