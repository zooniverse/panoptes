require 'spec_helper'

RSpec.describe NotifySubjectSelectorOfChangeWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow, :designator) }
  let(:subject_selector) { workflow.subject_selector }

  before do
    allow(Subjects::DesignatorSelector).to receive(:new).with(workflow).and_return(subject_selector)
  end

  it "should be retryable 3 times" do
    retry_count = worker.class.get_sidekiq_options['retry']
    expect(retry_count).to eq(3)
  end

  describe "#perform" do
    it "tells subject selector to reload its workflow" do
      expect(subject_selector).to receive(:reload_workflow)
      worker.perform(workflow.id)
    end

    it "should gracefully handle a missing workflow lookup" do
      expect{worker.perform(-1)}.not_to raise_error
    end
  end
end
