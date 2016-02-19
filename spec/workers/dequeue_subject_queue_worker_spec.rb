require "spec_helper"

RSpec.describe DequeueSubjectQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { workflow.project.owner }
  let(:sms_ids) { (1..10).to_a }
  let(:queue) do
    create(:subject_queue, user: user, workflow: workflow, set_member_subject_ids: sms_ids)
  end

  describe "#perform" do

    it 'should call dequeue on subject queue' do
      expect_any_instance_of(SubjectQueue)
        .to receive(:dequeue_update)
        .with(sms_ids)
      subject.perform(queue.id, sms_ids)
    end

    context "with an empty set of sms_ids" do

      it "should not call dequeue" do
        expect_any_instance_of(SubjectQueue).not_to receive(:dequeue_update)
        subject.perform(queue.id, [])
      end
    end

    context "when the queue does not exist" do
      it 'should not raise an error' do
        expect { subject.perform(-1, sms_ids) }.to_not raise_error
      end
    end
  end
end
