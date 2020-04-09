# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecentSweeperWorker do
  subject(:worker) { described_class.new }

  let(:marked_recent) { create(:recent, mark_remove: true) }
  let(:recent) { create(:recent) }

  before do
    marked_recent
    recent
  end

  it 'is scheduled to run hourly' do
    expect(worker.class.schedule.to_s).to eq('Hourly')
  end

  it 'removes all recents marked for removal' do
    expect {
      worker.perform
    }.to change {
      Recent.where(mark_remove: true).count
    }.from(1).to(0)
  end

  it 'leaves all recents not marked for removal' do
    expect {
      worker.perform
    }.not_to change {
      Recent.where(mark_remove: false).count
    }
  end
end
