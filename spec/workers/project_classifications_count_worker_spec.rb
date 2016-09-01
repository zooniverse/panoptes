require 'spec_helper'

RSpec.describe ProjectClassificationsCountWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let!(:project) { workflow.project }

  describe "#perform" do
    # temp fix - remove this once we've cleared the jam
    # and figured out how to do the counting for certain projects
    it "should return nil" do
      expect(worker.perform(project.id)).to be_nil
    end

    # it 'calls the workflow counter to update the workflow counts' do
    #   expect_any_instance_of(WorkflowCounter)
    #     .to receive(:classifications)
    #   expect_any_instance_of(Workflow)
    #     .to receive(:update_column)
    #     .with(:classifications_count, anything)
    #   worker.perform(project.id)
    # end
    #
    # it 'calls the project counter to update the project counts' do
    #   expect_any_instance_of(ProjectCounter)
    #     .to receive(:classifications)
    #   expect_any_instance_of(Project)
    #     .to receive(:update_column)
    #     .with(:classifications_count, anything)
    #   worker.perform(project.id)
    # end
  end
end
