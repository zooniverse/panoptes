require 'spec_helper'

RSpec.describe SeenCellectWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow) }
  let(:subject_id) { 2 }
  let(:user_id) { 1 }

  it "should be retryable 3 times" do
    retry_count = worker.class.get_sidekiq_options['retry']
    expect(retry_count).to eq(3)
  end

  describe "#perform" do
    it "should gracefully handle a missing workflow lookup" do
      expect{
        worker.perform(-1, user_id, subject_id)
      }.not_to raise_error
    end

    context "when cellect is off" do
      it "should not call cellect" do
        expect(Subjects::CellectClient).not_to receive(:add_seen)
        worker.perform(workflow.id, user_id, subject_id)
      end
    end

    context "when cellect is on" do
      before do
        allow(Panoptes).to receive(:cellect_on).and_return(true)
      end

      it "should not call to cellect if the workflow is not set to use it" do
        expect(Subjects::CellectClient).not_to receive(:add_seen)
        worker.perform(workflow.id, user_id, subject_id)
      end

      context "when the workflow is using cellect" do
        before do
          allow_any_instance_of(Workflow)
          .to receive(:using_cellect?).and_return(true)
        end

        it "should not call to cellect if the user is nil" do
          expect(Subjects::CellectClient).not_to receive(:add_seen)
          worker.perform(workflow.id, nil, subject_id)
        end

        it "should request that cellect add the seen for the subject" do
          expect(Subjects::CellectClient)
            .to receive(:add_seen)
            .with(workflow.id, user_id, subject_id)
          worker.perform(workflow.id, user_id, subject_id)
        end
      end
    end
  end
end
