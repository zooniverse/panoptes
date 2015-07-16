require 'spec_helper'

RSpec.describe SubjectRetirementWorker do
  let(:worker) { described_class.new }

  let(:sms) { create(:set_member_subject) }
  let(:subject) { sms.subject }
  let(:workflow) { create(:workflow, subject_sets: [sms.subject_set]) }
  let!(:queue) { create(:subject_queue, workflow: workflow, set_member_subject_ids: [sms.id]) }


  describe "#perform" do
    context "when the workflow project is live" do
      before { workflow.project.update! live: true }

      it 'should retire the subject for the workflow' do
        expect_any_instance_of(SubjectLifecycle).to receive(:retire_for).with(workflow)
        worker.perform(subject.id, workflow.id)
      end
    end

    context "when the project is not live" do
      before { workflow.project.update! live: false }

      it 'does not mark the subject as retired' do
        expect_any_instance_of(SubjectLifecycle).to receive(:retire_for).with(workflow).never
        worker.perform(subject.id, workflow.id)
      end
    end
  end
end
