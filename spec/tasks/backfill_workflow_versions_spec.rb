# backfill_workflow_versions_spec.rb

require 'spec_helper'

describe Tasks::BackfillWorkflowVersions do
  it 'creates workflow_versions for major changes', :versioning do
    workflow = create :workflow
    workflow.tasks['interest']['next'] = "none"
    workflow.save!
    workflow.tasks['interest']['next'] = "shape"
    workflow.save!

    workflow.workflow_versions.destroy_all

    described_class.new.backfill(workflow)
    expect(workflow.reload.workflow_versions.count).to eq(3)
  end
end
