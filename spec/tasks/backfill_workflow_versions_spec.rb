# backfill_workflow_versions_spec.rb

require 'spec_helper'

describe Tasks::BackfillWorkflowVersions do
  it 'creates workflow_versions for major changes', :versioning do
    workflow = create :workflow, tasks: {status: "one"}
    workflow.update! tasks: {status: "two"}
    workflow.update! tasks: {status: "three"}

    workflow.workflow_versions.destroy_all

    described_class.new.backfill(workflow)
    workflow.reload

    expect(workflow.workflow_versions.count).to eq(3)
    expect(workflow.workflow_versions.find_by(major_number: 1, minor_number: 1).tasks).to eq("status" => "one")
    expect(workflow.workflow_versions.find_by(major_number: 2, minor_number: 1).tasks).to eq("status" => "two")
    expect(workflow.workflow_versions.find_by(major_number: 3, minor_number: 1).tasks).to eq("status" => "three")
  end

  it 'creates workflow_versions for minor changes', :versioning do
    workflow = create :workflow
    workflow.primary_content.update! strings: workflow.primary_content.strings.merge('interest.question' => 'Foo')
    workflow.primary_content.update! strings: workflow.primary_content.strings.merge('interest.question' => 'Bar')

    workflow.workflow_versions.destroy_all

    described_class.new.backfill(workflow)
    workflow.reload

    expect(workflow.workflow_versions.count).to eq(3)
    expect(workflow.workflow_versions.find_by(major_number: 1, minor_number: 1).strings['interest.question']).to eq("Draw a circle")
    expect(workflow.workflow_versions.find_by(major_number: 1, minor_number: 2).strings['interest.question']).to eq("Foo")
    expect(workflow.workflow_versions.find_by(major_number: 1, minor_number: 3).strings['interest.question']).to eq("Bar")
  end
end
