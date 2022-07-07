require 'spec_helper'

RSpec.describe ClassificationCountWorker do
  let(:worker) { described_class.new }
  let(:subject_set) { project.workflows.first.subject_sets.first }
  let(:workflow_id) { project.workflows.first.id }
  let(:sms) { create(:set_member_subject, subject_set: subject_set) }

  describe "#perform" do
    context "when the workflow project is live" do
      let(:project) { create(:full_project, live: true) }

      context "when the flipper flag is disabled" do
        it "should not run the counters" do
          Flipper.disable(:classification_counters)
          expect(SubjectWorkflowStatus).not_to receive(:increment_counter)
          worker.perform(sms.subject_id, workflow_id)
        end
      end

      context "when the count model exists" do
        let!(:count) do
          create(:subject_workflow_status, subject: sms.subject, workflow_id: workflow_id)
        end

        it 'should incremement the classifications_count counter' do
          expect(SubjectWorkflowStatus)
            .to receive(:increment_counter)
            .with(:classifications_count, count.id)
          worker.perform(sms.subject_id, workflow_id)
        end

        it 'should call a worker to accurately count the classifications' do
          expect(SubjectWorkflowStatusCountWorker)
            .to receive(:perform_async)
            .with(count.id)
          worker.perform(sms.subject_id, workflow_id)
        end
      end

      context "when the count does not exist" do
        subject do
          SubjectWorkflowStatus.where(subject_id: sms.subject_id,
                                     workflow_id: workflow_id).first
        end

        before(:each) do
          worker.perform(sms.subject_id, workflow_id)
        end

        it 'should create a new count' do
          expect(subject).to_not be_nil
        end
      end

      it 'queues up a count update for project and workflow' do
        expect(WorkflowClassificationsCountWorker)
          .to receive(:perform_in)
          .with(5.seconds, workflow_id)
        worker.perform(sms.subject_id, workflow_id)
      end

      it 'should queue the retirement worker' do
        expect(RetirementWorker).to receive(:perform_async)
        worker.perform(sms.subject_id, workflow_id)
      end
    end

    context "when the project is not live" do
      let(:project) { create(:full_project, live: false) }

      let!(:count) do
        create(:subject_workflow_status, subject: sms.subject, workflow_id: workflow_id)
      end

      it 'should not increment the count' do
        expect do
          worker.perform(sms.subject_id, workflow_id)
          count.reload
        end.to_not change{count.classifications_count}
      end

      it 'should not queue the retirment worker' do
        expect(RetirementWorker).to_not receive(:perform_async)
        worker.perform(sms.subject_id, workflow_id)
      end
    end
  end
end
