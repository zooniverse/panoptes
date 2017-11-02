require 'spec_helper'

RSpec.describe NotifySubjectSelectorOfSeenWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow, :designator) }
  let(:subject_selector) { workflow.subject_selector }
  let(:client) { double(DesignatorClient, add_seen: true) }
  let(:subject_id) { 2 }
  let(:user_id) { 1 }

  before do
    allow(Subjects::DesignatorSelector).to receive(:new).with(workflow).and_return(subject_selector)
  end

  it "should be retryable 3 times" do
    retry_count = worker.class.get_sidekiq_options['retry']
    expect(retry_count).to eq(3)
  end

  describe "#perform" do
    it "tells subject selector to add the seen for the subject" do
      expect(subject_selector).to receive(:add_seen).with(user_id, subject_id)
      worker.perform(workflow.id, user_id, subject_id)
    end

    it "should not call to subject selector if the user is nil" do
      expect(subject_selector).not_to receive(:add_seen)
      worker.perform(workflow.id, nil, subject_id)
    end

    it "should gracefully handle a missing workflow lookup" do
      expect{
        worker.perform(-1, user_id, subject_id)
      }.not_to raise_error
    end
  end
end
