require 'spec_helper'

RSpec.describe ClassificationsNightlyDumpWorker do
  let(:worker) { described_class.new }

  let!(:project1) { create :project }

  before do
    allow(ClassificationsDumpWorker).to receive(:perform_async)
  end

  describe "#perform" do
    it 'enqueues a dump for all projects' do
      from = 1.day.ago
      till = Time.now
      worker.perform(from.to_f, till.to_f)
      expect(ClassificationsDumpWorker).to have_received(:perform_async).with(project1.id, project1.classifications_nightly_exports.last.id, from, till)
    end
  end
end
