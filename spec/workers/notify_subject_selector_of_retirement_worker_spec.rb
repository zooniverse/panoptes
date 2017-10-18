require 'spec_helper'

RSpec.describe NotifySubjectSelectorOfRetirementWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow, :designator) }
  let(:subject_selector) { workflow.subject_selector }
  let(:subject_id) { 1 }
  let(:subject_set_id) { 2 }

  before do
    allow(Subjects::DesignatorSelector).to receive(:new).with(workflow).and_return(subject_selector)
  end

  it "should be retryable 3 times" do
    retry_count = worker.class.get_sidekiq_options['retry']
    expect(retry_count).to eq(3)
  end

  describe "#perform" do
    it "tells subject selector to retire subject for the workflow and set" do
      expect(subject_selector).to receive(:remove_subject).with(subject_id)
      worker.perform(subject_id, workflow.id)
    end

    it "should gracefully handle a missing workflow lookup" do
      expect{worker.perform(subject_id, -1)}.not_to raise_error
    end
  end
end
