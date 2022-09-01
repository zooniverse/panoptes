require 'spec_helper'

describe RequeueClassificationsWorker do
  let(:worker) { described_class.new }
  let(:classification) { create(:classification) }
  let(:lifecycled_classification) do
    create(:classification, lifecycled_at: Time.zone.now)
  end

  it{ is_expected.to be_a Sidekiq::Worker }

  describe 'schedule' do
    it_behaves_like 'is schedulable' do
      let(:now) { Time.now.utc }
      let(:cron_sched) { '*/15 * * * *' }
      let(:class_name) { described_class.name }
      let(:enqueued_times) {
        [
          Time.new(now.year, now.month, now.day, now.hour, 0, 0).utc,
          Time.new(now.year, now.month, now.day, now.hour, 15, 0).utc,
          Time.new(now.year, now.month, now.day, now.hour, 30, 0).utc,
          Time.new(now.year, now.month, now.day, now.hour, 45, 0).utc
        ]
      }
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

    context "when the worker is disabled via env variable" do

      it "should not run the worker" do
        allow(Panoptes).to receive(:disable_lifecycle_worker).and_return(true)
        expect(worker).not_to receive(:non_lifecycled)
        worker.perform
      end
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
