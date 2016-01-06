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

  it 'enqueues all the non-lifecycled classifications' do
    classification
    lifecycled_classification
    expect_any_instance_of(ClassificationLifecycle)
      .to receive(:queue).with(:create).once
    worker.perform
  end
end
