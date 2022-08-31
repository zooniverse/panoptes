require 'spec_helper'

RSpec.describe ClassificationHeartbeatWorker do
  let(:worker) { described_class.new }
  let!(:classification) { create(:classification) }

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

      it 'should not notify zoo team via email' do
        expect{ worker.perform }.not_to change{ ActionMailer::Base.deliveries.count }
      end

      context "production env" do
        before do
          allow(worker).to receive(:heartbeat_check?).and_return(true)
        end

        it 'should raise an error via honeybadger' do
          expect(Honeybadger).to receive(:notify)
          worker.perform
        end

        it 'should notify zoo team via email' do
          expect{ worker.perform }.to change{ ActionMailer::Base.deliveries.count }.by(1)
        end
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
