require "spec_helper"
require 'subjects/cellect_session'

RSpec.describe EnqueueSubjectQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { workflow.project.owner }
  let(:queue) do
    create(:subject_queue,
      workflow: workflow,
      user: user,
      subject_set_id: subject_set.id
    )
  end

  describe "#perform" do
    let(:result_ids) { [] }
    let(:selector) { instance_double("Subjects::StrategySelection") }
    before do
      allow(selector).to receive(:select).and_return(result_ids)
    end

    it "should not raise an error if there is no queue" do
      expect { subject.perform(-1) }.not_to raise_error
    end

    it "should request subjects from the strategy selector" do
      expect(Subjects::StrategySelection)
        .to receive(:new)
        .with(workflow, user, subject_set.id, SubjectQueue::DEFAULT_LENGTH, nil)
        .and_return(selector)
      subject.perform(queue.id)
    end

    it "should not attempt to queue an empty selection set" do
      expect_any_instance_of(SubjectQueue).not_to receive(:enqueue_update)
      subject.perform(queue.id)
    end

    context "when subjects are selected" do
      let(:result_ids) { (1..10).to_a }
      before do
        expect(Subjects::StrategySelection).to receive(:new).and_return(selector)
      end

      it "should enqueue new data" do
        subject.perform(queue.id)
        expect(queue.reload.set_member_subject_ids.length).to eq(result_ids.length)
      end

      it "should attempt to queue the selected set" do
        expect_any_instance_of(SubjectQueue).to receive(:enqueue_update)
        subject.perform(queue.id)
      end
    end
  end
end
