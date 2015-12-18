require 'spec_helper'

describe CalculateProjectActivityWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:project) { workflow.project }
  let(:user) { project.user }

  let(:classifications) do
    create_list(:classification, 2, project: project, workflow: workflow)
    c = create(:classification, project: project, workflow: workflow)
    c.update_column(:created_at, 25.hours.ago)
  end

  describe '#perform' do
    it 'should update the workflow and project activity' do
      classifications
      count = worker.workflow_activity(workflow)
      expect_any_instance_of(Workflow).to receive(:update_columns).with(activity: count)
      expect_any_instance_of(Project).to receive(:update_columns).with(activity: count)
      worker.perform(project.id)
    end

    context "when it can't find the project" do
      it "should fail quickly" do
        expect(Project).not_to receive(:transaction)
        worker.perform("-1")
      end
    end
  end

  describe '#workflow_activity' do
    it 'returns 0 when no classifications have been made yet' do
      expect(worker.workflow_activity(workflow)).to eq(0)
    end

    context "with classifications" do
      it 'should only count classification in last 24 hours' do
        classifications
        expect(worker.workflow_activity(workflow)).to eq(2)
      end
    end
  end
end
