require 'spec_helper'

RSpec.describe RetirementWorker do
  let(:worker) { described_class.new }
  let(:sms) { create :set_member_subject }
  let(:workflow) { create :workflow, subject_sets: [sms.subject_set] }
  let(:count) { create(:subject_workflow_count, subject: sms.subject, workflow: workflow) }
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
    context "workflow is finsihed" do
      it 'should set workflow.active to false' do
        allow(workflow).to receive(:finished?).and_return(true)
        expect do
          worker.deactivate_workflow!(workflow)
        end.to change{Workflow.find(workflow.id).active}.from(true).to(false)
      end

      context "when the workflow optimistic lock is updated" do
        it 'should save the changes and not raise an error' do
          allow(workflow).to receive(:finished?).and_return(true)
          Workflow.find(workflow.id).touch
          expect { worker.deactivate_workflow!(workflow) }.to_not raise_error
        end
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

  describe "#push_counters_to_event_stream" do
    before(:each) do
      allow(EventStream).to receive(:push)
    end

    it 'should publish new counts to event stream upon retiring' do
      allow_any_instance_of(SubjectWorkflowCount).to receive(:retire?).and_return(true)
      worker.perform(count)
      expect(EventStream).to have_received(:push).once
    end
  end
end
