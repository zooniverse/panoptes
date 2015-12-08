require 'spec_helper'

describe CalculateCompletenessWorker do
  let(:worker) { described_class.new }

  it{ is_expected.to be_a Sidekiq::Worker }

  it 'enqueues a completeness calculation for each project', :aggregate_failures do
    project1 = create :project
    project2 = create :project

    expect(CalculateProjectCompletenessWorker).to receive(:perform_in).with(an_instance_of(Float), project1.id)
    expect(CalculateProjectCompletenessWorker).to receive(:perform_in).with(an_instance_of(Float), project2.id)

    worker.perform
  end

  it 'only calculates active projects' do
    project = create :project
    project.disable!
    expect(CalculateProjectCompletenessWorker).to receive(:perform_async).with(project.id).never
    worker.perform
  end
end
