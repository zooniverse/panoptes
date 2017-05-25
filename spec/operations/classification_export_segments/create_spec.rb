require 'spec_helper'

describe ClassificationsExportSegments::Create do
  let(:project) { create :project}
  let(:workflow) { create :workflow, project: project }
  let(:user) { project.owner }
  let(:subject) { create :subject, project: project }
  let(:operation) do
    described_class.with(project: project, links: {workflow: workflow.id}, api_user: ApiUser.new(user))
  end

  it 'creates a segment when there is no segment yet' do
    create :classification, workflow: workflow, subject_ids: [subject.id], user: nil
    segment = operation.run!
    expect(segment).to be_present
    expect(segment.classifications_in_segment.count).to eq(1)
  end

  it 'creates the next segment' do
    create :classification, workflow: workflow, subject_ids: [subject.id], user: nil
    first_segment = operation.run!

    classifications = create_list :classification, 3, workflow: workflow, subject_ids: [subject.id], user: nil
    next_segment = operation.run!

    expect(next_segment.first_classification_id).to eq(classifications[0].id)
    expect(next_segment.last_classification_id).to eq(classifications[-1].id)
  end

  it 'does not create a segment if there are no classifications' do
    first_segment = operation.run!
    expect(first_segment).to be_nil
  end

  it 'does not create a segment if the current segment contains all classifications' do
    classifications = create_list :classification, 3, workflow: workflow, subject_ids: [subject.id], user: nil
    operation.run!

    segment = operation.run!
    expect(segment).to be_nil

  end

  it 'queues the export segment worker' do
    classifications = create_list :classification, 3, workflow: workflow, subject_ids: [subject.id], user: nil
    operation.run!
    expect(ClassificationsExportSegmentWorker.jobs.size).to eq(1)
  end
end
