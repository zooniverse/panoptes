require 'spec_helper'

describe RequeueClassificationsWorker do
  let(:worker) { described_class.new }
  let(:classification) { create(:classification) }
  let(:lifecycled_classification) do
    create(:classification, lifecycled_at: Time.zone.now)
  end

  it{ is_expected.to be_a Sidekiq::Worker }

  describe 'schedule' do
    it "should have a valid schedule" do
      expect(described_class.schedule.to_s)
      .to match(/Hourly on the 0th, 15th, 30th, and 45th minutes of the hour/)
    end
  end

  describe "perform" do
    before do
      classification
      lifecycled_classification
    end

    it 'should not enqueue live data that is in the process of queueing' do
      expect(ClassificationWorker).not_to receive(:perform_async)
      worker.perform
    end

    context "with non-lifecycled classification outside the live window" do
      let(:outside_live_window) do
        Panoptes.lifecycled_live_window.minutes.ago
      end
      let(:classification) do
        c = create(:classification)
        c.update_column(:created_at, outside_live_window)
        c
      end

      it 'enqueues all the non-lifecycled classifications' do
        expect(ClassificationWorker)
          .to receive(:perform_async)
          .with(classification.id, :create)
          .once
        worker.perform
      end
    end
  end
end
