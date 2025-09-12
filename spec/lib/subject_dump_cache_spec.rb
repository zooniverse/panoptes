require 'spec_helper'

RSpec.describe SubjectDumpCache do
  let(:project) { create(:project) }
  let(:workflow1) { create(:workflow, project: project) }
  let(:workflow2) { create(:workflow, project: project) }
  let(:subject_set) { create(:subject_set, project: project, workflows: [workflow1, workflow2]) }
  let(:subject) { create(:subject, project: project, uploader: project.owner) }

  before do
    create(:set_member_subject, subject_set: subject_set, subject: subject)
    create(:subject_workflow_status, workflow: workflow1, subject: subject)
    create(:subject_workflow_status, workflow: workflow2, subject: subject)
  end

  it 'preloads statuses and subject set workflows for a batch' do
    cache = SubjectDumpCache.new
    cache.reset_for_batch([subject], project.workflows.pluck(:id))

    statuses = cache.statuses_for_subject(subject.id)
    expect(statuses.keys).to match_array([workflow1.id, workflow2.id])
    expect(statuses[workflow1.id]).to be_a(SubjectWorkflowStatus)

    ssw = cache.subject_set_workflows_for_set(subject_set.id)
    expect(ssw).to all(be_a(SubjectSetsWorkflow))
    expect(ssw.map(&:workflow_id)).to include(workflow1.id, workflow2.id)
  end
end

