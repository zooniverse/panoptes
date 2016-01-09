require 'spec_helper'

RSpec.describe RetireCellectWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow_with_subjects) }
  let(:subject) { workflow.subjects.first }
  let(:subject_set) { subject.subject_sets.first }

  it "should be retryable 3 times" do
    retry_count = worker.class.get_sidekiq_options['retry']
    expect(retry_count).to eq(3)
  end

  describe "#perform" do
    it "should gracefully handle a missing workflow lookup" do
      expect{worker.perform(subject.id, -1)}.not_to raise_error
    end

    context "when cellect is off" do
      it "should not call cellect" do
        expect(Subjects::CellectClient).not_to receive(:remove_subject)
        worker.perform(subject.id, workflow.id)
      end
    end

    context "when cellect is on" do
      before do
        allow(Panoptes).to receive(:cellect_on).and_return(true)
      end

      it "should not call to cellect if the workflow is not set to use it" do
        expect(Subjects::CellectClient).not_to receive(:remove_subject)
        worker.perform(subject.id, workflow.id)
      end

      context "when the workflow is using cellect" do
        before do
          allow_any_instance_of(Workflow)
          .to receive(:using_cellect?).and_return(true)
        end

        it "should request that cellect retire for the workflow and set" do
          expect(Subjects::CellectClient)
            .to receive(:remove_subject)
            .with(subject.id, workflow.id, subject_set.id)
          worker.perform(subject.id, workflow.id)
        end
      end
    end
  end
end
