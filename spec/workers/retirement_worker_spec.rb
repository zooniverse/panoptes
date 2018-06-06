require 'spec_helper'

RSpec.describe RetirementWorker do
  let(:worker) { described_class.new }
  let(:sms) { create :set_member_subject }
  let(:workflow) { create :workflow, subject_sets: [sms.subject_set] }
  let(:status) { create(:subject_workflow_status, subject: sms.subject, workflow: workflow) }
  let(:setup_status_find) do
    allow(SubjectWorkflowStatus).to receive(:find).with(status.id).and_return(status)
  end

  describe "#perform" do
    it "should ignore any missing SubjectWorkflowStatus resources" do
      expect{
        worker.perform(-1)
      }.not_to raise_error
    end

    context "sms is retireable" do
      before(:each) do
        allow(status).to receive(:retire?).and_return(true)
        setup_status_find
      end

      it 'should retire the subject for the workflow' do
        worker.perform(status.id)
        sms.reload
        expect(sms.retired_workflows).to include(workflow)
      end

      it 'should record a default reason for retirement' do
        expect { worker.perform(status.id) }.to change {
          status.reload.retirement_reason
        }.to("classification_count")
      end

      it 'should record the reason for retirement' do
        reason = "nothing_here"
        expect { worker.perform(status.id, reason) }.to change {
          status.reload.retirement_reason
        }.to(reason)
      end

      it 'should allow a nil reason for retirement' do
        expect { worker.perform(status.id, nil) }.not_to change {
          status.reload.retirement_reason
        }
      end

      it 'should call the workflow retired statuser worker' do
        expect(WorkflowRetiredCountWorker)
          .to receive(:perform_async)
          .with(status.workflow.id)
        worker.perform(status.id)
      end

      it "should call the publish retire event worker" do
        expect(PublishRetirementEventWorker)
          .to receive(:perform_async)
          .with(workflow.id)
        worker.perform(status.id)
      end

      it "should notify the subject selector" do
        expect(NotifySubjectSelectorOfRetirementWorker)
          .to receive(:perform_async)
          .with(sms.subject_id, workflow.id)
        worker.perform(status.id)
      end
    end

    shared_examples "it does not run the post retirement workers" do
      it 'should not queue a notify selector retirement' do
        expect(NotifySubjectSelectorOfRetirementWorker).not_to receive(:perform_async)
        worker.perform(status.id)
      end

      it 'should not queue a retired status worker' do
        expect(WorkflowRetiredCountWorker).not_to receive(:perform_async)
        worker.perform(status.id)
      end

      it "should not call the publish retire event worker" do
        expect(PublishRetirementEventWorker).not_to receive(:perform_async)
        worker.perform(status.id)
      end
    end

    context "sms is not retireable" do
      before do
        allow(status).to receive(:retire?).and_return(false)
        setup_status_find
      end

      it 'should not retire subject for the workflow' do
        worker.perform(status.id)
        sms.reload
        expect(sms.retired_workflows).to_not include(workflow)
      end

      context "with a force_retire param" do
        it "should retire the subject" do
          expect(status).to receive(:retire!).with("classification_count")
          worker.perform(status.id, force_retire: true)
        end
      end

      it_behaves_like "it does not run the post retirement workers"
    end

    context 'when the sms is already retired' do
      before(:each) do
        allow(status).to receive(:retired_at).and_return 1.minute.ago.utc
        setup_status_find
      end

      it 'should not retire the subject for the workflow' do
        expect(status).to_not receive :retire!
        worker.perform status.id
      end

      context "with a force_retire param" do
        it "should not retire the subject" do
          expect(status).not_to receive(:retire!)
          worker.perform(status.id, force_retire: true)
        end
      end

      it_behaves_like "it does not run the post retirement workers"
    end
  end
end
