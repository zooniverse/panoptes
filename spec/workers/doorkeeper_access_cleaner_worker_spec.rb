require 'spec_helper'

describe DoorkeeperAccessCleanerWorker do
  let(:worker) { described_class.new }

  it{ is_expected.to be_a Sidekiq::Worker }

  describe 'schedule' do
    it_behaves_like 'is schedulable' do
      let(:now) { Time.now.utc }
      let(:cron_sched) { '0 0 * * *' }
      let(:class_name) { described_class.name }
      let(:enqueued_times) {
        [
          Time.new(now.year, now.month, now.day, 0, 0, 0).utc
        ]
      }
    end
  end

  describe "perform" do
    let(:cleaner) { instance_double(Doorkeeper::AccessCleanup) }

    it 'should tell doorkeeper to cleanup' do
      allow(Doorkeeper::AccessCleanup).to receive(:new).and_return(cleaner)
      expect(cleaner).to receive(:cleanup!)
      worker.perform
    end
  end
end
