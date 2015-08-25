require "spec_helper"

RSpec.describe WorkflowContentsDumpWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow)}
  let(:project) { workflow.project }

  describe "#perform" do
    it_behaves_like "dump worker", WorkflowContentDataMailerWorker, "project_workflow_contents_export" do
      let(:num_entries) { 2 }
    end
  end

  context "with a versioned workflow content" do

    with_versioning do
      let(:q_workflow) { build(:question_task_workflow) }
      let(:strings) { q_workflow.workflow_contents.first.strings }
      let(:workflow_content) { workflow.workflow_contents.first }

      before(:each) do
        workflow_content.update(strings: strings)
      end

      it "should append all previous versions to the csv file" do
        aggregate_failures "versions" do
          expect_any_instance_of(CSV).to receive(:<<).exactly(3).times.and_call_original
          [ workflow_content, workflow_content.previous_version ].each do |version|
            expect_any_instance_of(Formatter::Csv::WorkflowContent).to receive(:to_array)
            .with(version).and_call_original
          end
          worker.perform(project.id)
        end
      end
    end
  end
end
