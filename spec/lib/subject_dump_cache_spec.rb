# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubjectDumpCache do
  let(:project) { create(:project) }
  let(:workflow1) { create(:workflow, project: project) }
  let(:workflow2) { create(:workflow, project: project) }
  let(:subject_set) { create(:subject_set, project: project, workflows: [workflow1, workflow2]) }
  let(:export_subject) { create(:subject, project: project, uploader: project.owner) }

  before do
    create(:set_member_subject, subject_set: subject_set, subject: export_subject)
    create(:subject_workflow_status, workflow: workflow1, subject: export_subject)
    create(:subject_workflow_status, workflow: workflow2, subject: export_subject)
  end

  it 'preloads statuses for a batch' do
    cache = described_class.new
    cache.reset_for_batch([export_subject], project.workflows.pluck(:id))

    statuses = cache.statuses_for_subject(export_subject.id)
    expect(statuses.keys).to match_array([workflow1.id, workflow2.id])
    expect(statuses[workflow1.id]).to be_a(SubjectWorkflowStatus)
  end

  it 'preloads subject set workflows for a batch' do
    cache = described_class.new
    cache.reset_for_batch([export_subject], project.workflows.pluck(:id))

    ssw = cache.subject_set_workflows_for_set(subject_set.id)
    expect(ssw).to all(be_a(SubjectSetsWorkflow))
    expect(ssw.map(&:workflow_id)).to include(workflow1.id, workflow2.id)
  end
end
