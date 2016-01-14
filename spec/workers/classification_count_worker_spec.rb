require 'spec_helper'

RSpec.describe ClassificationCountWorker do
  let(:worker) { described_class.new }
  let(:subject_set) { project.workflows.first.subject_sets.first }
  let(:workflow_id) { project.workflows.first.id }
  let(:sms) { create(:set_member_subject, subject_set: subject_set) }

  describe "#perform" do
    context "when the workflow project is live" do
      let(:project) { create(:full_project, live: true) }

      context "when the count model exists" do
        let!(:count) do
          create(:subject_workflow_count, subject: sms.subject, workflow_id: workflow_id)
        end

        it 'should increment the classifications_count' do
          expect do
            worker.perform(sms.subject_id, workflow_id)
            count.reload
          end.to change{count.classifications_count}.from(1).to(2)
        end
      end

      context "when the count does not exist" do
        subject do
          SubjectWorkflowCount.where(subject_id: sms.subject_id,
                                     workflow_id: workflow_id).first
        end

        before(:each) do
          worker.perform(sms.subject_id, workflow_id)
        end

        it 'should create a new count' do
          expect(subject).to_not be_nil
        end

        it 'should have a count of 1' do
          expect(subject.classifications_count).to eq(1)
        end
      end

      it 'queues up a count update for project and workflow' do
        expect(ProjectClassificationsCountWorker).to receive(:perform_async).with(project.id)
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
        create(:subject_workflow_count, subject: sms.subject, workflow_id: workflow_id)
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
