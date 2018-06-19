require 'spec_helper'

RSpec.describe RecentCreateWorker do
  let(:classification) { create(:classification) }

  it 'should call create_from_classification' do
    expect(Recent)
      .to receive(:create_from_classification)
      .with(classification)
    subject.perform(classification.id)
  end
end
