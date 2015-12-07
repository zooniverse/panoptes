require 'spec_helper'

describe CalculateActivityWorker do
  let(:worker) { described_class.new }

  it{ is_expected.to be_a Sidekiq::Worker }

  it 'enqueues a activity calculation for each project' do
    project1 = create :project
    project2 = create :project

    expect(CalculateProjectActivityWorker).to receive(:perform_async).with(project1.id)
    expect(CalculateProjectActivityWorker).to receive(:perform_async).with(project2.id)

    worker.perform
  end
end
