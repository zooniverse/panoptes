require 'spec_helper'

RSpec.describe RetirementWorker do
  let(:worker) { described_class.new }
  let(:count) { create(:subject_workflow_count) }
  let(:sms) { count.set_member_subject }
  let(:workflow) { count.workflow }
  let!(:queue) { create(:subject_queue, workflow: workflow, set_member_subject_ids: [sms.id]) }

  describe "#perform" do
    context "sms is retireable" do
      before(:each) do
        allow_any_instance_of(SubjectWorkflowCount).to receive(:retire?).and_return(true)
      end

      it 'should retire the subject for the workflow' do
        worker.perform(count)
        sms.reload
        expect(sms.retired_workflows).to include(workflow)
      end

      it "should increment the subject set's retirement count" do
        expect{ worker.perform(count.id) }.to change{
          Workflow.find(workflow.id).retired_set_member_subjects_count
        }.from(0).to(1)
      end

      it "should dequeue all instances of the subject" do
        worker.perform(count.id)
        queue.reload
        expect(queue.set_member_subject_ids).to_not include(sms.id)
      end
    end

    context "sms is not retireable" do
      it 'should not retire subject for the workflow' do
        allow_any_instance_of(SubjectWorkflowCount).to receive(:retire?).and_return(false)
        worker.perform(count)
        sms.reload
        expect(sms.retired_workflows).to_not include(workflow)
      end
    end
  end

  describe "#deactive_workflow!" do
    let(:workflow) { count.workflow }

    context "workflow is finsihed" do
      it 'should set workflow.active to false' do
        allow(workflow).to receive(:finished?).and_return(true)
        expect do
          worker.deactivate_workflow!(workflow)
        end.to change{Workflow.find(workflow.id).active}.from(true).to(false)
      end
    end

    context "workflow is not finished" do
      it 'should not set workflow.actvive to false' do
        allow(workflow).to receive(:finished?).and_return(false)
        expect do
          worker.deactivate_workflow!(workflow)
        end.to_not change{Workflow.find(workflow.id).active}
      end
    end
  end
end
