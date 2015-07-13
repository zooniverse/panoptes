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
        workflow.update! subject_sets: [sms.subject_set]
        workflow.project.update! live: true
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
end
