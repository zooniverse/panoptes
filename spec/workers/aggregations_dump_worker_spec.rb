require "spec_helper"

RSpec.describe AggregationsDumpWorker do

  let(:agg_double) {double(aggregate: nil)}

  before(:each) do
    allow(AggregationClient).to receive(:new).and_return(agg_double)
  end

  let!(:project) { create(:project) }
  let!(:medium) { create(:medium, type: "project_aggregations_export", content_type: "application/x-gzip") }

  subject { described_class.new }

  it 'should create a medium with put_expires equal to one day in seconds' do
    expect do
      subject.perform(project, medium)
      medium.reload
    end.to change{medium.put_expires}.from(nil).to(86400)
  end

  it 'should send an aggregate message to the AggregationClient' do
    expect(agg_double).to receive(:aggregate)
    subject.perform(project, medium)
  end
end
