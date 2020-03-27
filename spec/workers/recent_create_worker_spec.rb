require 'spec_helper'

RSpec.describe RecentCreateWorker do
  let(:classification) { create(:classification) }

  it 'should call create_from_classification' do
    expect(Recent)
      .to receive(:create_from_classification)
      .with(classification)
    subject.perform(classification.id)
  end

  it 'should mark all recents past the capped ammount for deletion' do
    # TODO: allow the capped collection size
    # to be stubbed to only have to cleanup 1 out of 2
    classification = create(:classification_with_recents)
    classification.recents.last.id
    recent_to_be_marked = classification.recents.last.id
    expect {
      subject.perform(classification.id)
    }.to change {
        Recent.where(
          id: recent_to_be_marked,
          mark_remove: true
        ).count
      }.from(0).to(1)
  end

end
