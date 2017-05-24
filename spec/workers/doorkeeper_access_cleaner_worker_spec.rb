require 'spec_helper'

describe DoorkeeperAccessCleanerWorker do
  let(:worker) { described_class.new }

  it{ is_expected.to be_a Sidekiq::Worker }

  describe 'schedule' do
    it "should have a valid schedule" do
      expect(described_class.schedule.to_s).to match(/Daily/)
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
