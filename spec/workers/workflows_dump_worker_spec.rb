require "spec_helper"

RSpec.describe WorkflowsDumpWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow)}
  let(:project) { workflow.project }

  describe "#perform" do
    it_behaves_like "dump worker", WorkflowDataMailerWorker, "project_workflows_export" do
      let(:num_entries) { 2 }
    end
  end

  context "with a versioned workflow" do
    let(:q_workflow) { build(:workflow, :question_task) }
    let(:tasks) { q_workflow.tasks }

    before(:each) do
      updates = {
        tasks: tasks, pairwise: !workflow.pairwise,
        grouped: !workflow.grouped, prioritized: !workflow.prioritized
      }
      workflow.update(updates)
    end

    it "should append all previous versions to the csv file" do
      aggregate_failures "versions" do
        expect_any_instance_of(CSV).to receive(:<<).exactly(3).times.and_call_original
        workflow.workflow_versions.each do |version|
          expect_any_instance_of(Formatter::Csv::Workflow).to receive(:to_array)
            .with(version).and_call_original
        end
        worker.perform(project.id, "project")
      end
    end
  end
end
