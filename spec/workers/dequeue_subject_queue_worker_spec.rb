require "spec_helper"

RSpec.describe DequeueSubjectQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { workflow.project.owner }
  let(:sms_ids) { (1..10).to_a }

  describe "#perform" do

    it 'should call dequeue on subject queue' do
      expect(SubjectQueue).to receive(:dequeue).with(workflow, sms_ids, user: nil, set_id: nil)
      subject.perform(workflow.id, sms_ids)
    end

    context "with an empty set of sms_ids" do

      it "should not call dequeue" do
        expect(SubjectQueue).not_to receive(:dequeue)
        subject.perform(workflow.id, [])
      end
    end

    context "when the workflow does not exist" do
      it 'should not raise an error' do
        expect { subject.perform(-1, sms_ids) }.to_not raise_error
      end
    end

    context "with a user" do

      it 'should call dequeue on subject queue' do
        expect(SubjectQueue).to receive(:dequeue).with(workflow, sms_ids, user: user, set_id: nil)
        subject.perform(workflow.id, sms_ids, user)
      end
    end

    context "with a set id" do

      it 'should call dequeue on subject queue' do
        expect(SubjectQueue).to receive(:dequeue).with(workflow, sms_ids, user: nil, set_id: subject_set.id)
        subject.perform(workflow.id, sms_ids, nil, subject_set.id)
      end
    end

    context "with user and a subject set" do

      it 'should call dequeue on subject queue' do
        expect(SubjectQueue).to receive(:dequeue).with(workflow, sms_ids, user: user, set_id: subject_set.id)
        subject.perform(workflow.id, sms_ids, user, subject_set.id)
      end
    end
  end
end
