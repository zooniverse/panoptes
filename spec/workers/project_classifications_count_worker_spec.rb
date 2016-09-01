require 'spec_helper'

RSpec.describe ProjectClassificationsCountWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let!(:project) { workflow.project }

  describe "#perform" do

    it 'calls the workflow counter to update the workflow counts' do
      expect_any_instance_of(WorkflowCounter)
        .to receive(:classifications)
      expect_any_instance_of(Workflow)
        .to receive(:update_column)
        .with(:classifications_count, anything)
      worker.perform(project.id)
    end

    it 'calls the project counter to update the project counts' do
      expect_any_instance_of(ProjectCounter)
        .to receive(:classifications)
      expect_any_instance_of(Project)
        .to receive(:update_column)
        .with(:classifications_count, anything)
      worker.perform(project.id)
    end
  end
end
