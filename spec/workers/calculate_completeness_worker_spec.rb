require 'spec_helper'

describe CalculateCompletenessWorker do
  let(:worker) { described_class.new }

  it{ is_expected.to be_a Sidekiq::Worker }

  it 'enqueues a completeness calculation for each project' do
    project1 = create :project
    project2 = create :project

    expect(CalculateProjectCompletenessWorker).to receive(:perform_async).with(project1.id)
    expect(CalculateProjectCompletenessWorker).to receive(:perform_async).with(project2.id)

    worker.perform
  end
end
