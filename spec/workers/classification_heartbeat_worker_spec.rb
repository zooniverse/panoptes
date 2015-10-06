require 'spec_helper'

RSpec.describe ClassificationHeartbeatWorker do
  let(:worker) { described_class.new }
  let!(:classification) { create(:classification) }

  it{ is_expected.to be_a Sidekiq::Worker }

  describe 'schedule' do

    it "should have a valid schedule" do
      expect(described_class.schedule.to_s).to match(/Hourly on the 0th, 15th, 30th, and 45th minutes of the hour/)
    end
  end

  describe "#perform" do
    let(:offset) { Panoptes::ClassificationHeartbeat.window_period.seconds - 5.minutes }

    before(:each) do
      allow_any_instance_of(Classification).to receive(:created_at).and_return(DateTime.now - offset)
    end

    it 'should not raise an error' do
      expect { worker.perform }.not_to raise_error
    end

    context "when the last classification received falls outside the acceptable window" do
      let(:offset) { Panoptes::ClassificationHeartbeat.window_period.seconds + 1.minute }

      it 'should raise an error via honeybadger' do
        expect(Honeybadger).to receive(:notify)
        worker.perform
      end

      it 'should notify zoo team via email' do
        expect{ worker.perform }.to change{ ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "when the last classification received falls inside the acceptable window" do

      it 'should not raise an error via honeybadger' do
        expect(Honeybadger).not_to receive(:notify)
        worker.perform
      end

      it 'should not notify zoo team via email' do
        expect{ worker.perform }.not_to change{ ActionMailer::Base.deliveries.count }
      end
    end
  end
end
