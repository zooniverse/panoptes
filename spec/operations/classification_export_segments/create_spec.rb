require 'spec_helper'

describe ClassificationsExportSegments::Create do
  let(:workflow) { create :workflow }
  let(:user) { create :user }

  it 'creates a segment when there is no segment yet' do
    create :classification, workflow: workflow
    segment = described_class.run!(workflow_id: workflow.id, api_user: ApiUser.new(user))
    expect(segment).to be_present
    expect(segment.classifications_in_segment.count).to eq(1)
  end

  it 'creates the next segment' do
    create :classification, workflow: workflow
    first_segment = described_class.run!(workflow_id: workflow.id, api_user: ApiUser.new(user))

    classifications = create_list :classification, 3, workflow: workflow
    next_segment = described_class.run!(workflow_id: workflow.id, api_user: ApiUser.new(user))

    expect(next_segment.first_classification_id).to eq(classifications[0].id)
    expect(next_segment.last_classification_id).to eq(classifications[-1].id)
  end

  it 'does not create a segment if there are no classifications' do
    first_segment = described_class.run!(workflow_id: workflow.id, api_user: ApiUser.new(user))
    expect(first_segment).to be_nil
  end

  it 'does not create a segment if the current segment contains all classifications' do
    classifications = create_list :classification, 3, workflow: workflow
    described_class.run!(workflow_id: workflow.id, api_user: ApiUser.new(user))

    segment = described_class.run!(workflow_id: workflow.id, api_user: ApiUser.new(user))
    expect(segment).to be_nil

  end

  it 'queues the export segment worker' do
    classifications = create_list :classification, 3, workflow: workflow
    described_class.run!(workflow_id: workflow.id, api_user: ApiUser.new(user))
    expect(ClassificationsExportSegmentWorker.jobs.size).to eq(1)
  end
end
