require "spec_helper"

describe Api::V1::WorkflowVersionsController, type: :controller do
  let(:private_project) { create(:project, private: true) }
  let(:public_project) { create(:project) }

  let(:public_workflow) { create(:workflow, project: public_project) }
  let(:private_workflow) { create(:workflow, project: private_project) }

  let(:public_workflow_version) { public_workflow.workflow_versions.last }
  let(:private_workflow_version) { private_workflow.workflow_versions.last }

  let!(:workflow_versions) do
    [
      public_workflow_version,
      private_workflow_version
    ]
  end

  let(:scopes) { %w(public project) }
  let(:api_resource_name) { "workflow_versions" }
  let(:api_resource_attributes) { %w(first_task tasks strings major_version minor_version) }
  let(:api_resource_links) { %w(workflow_versions.workflow) }
  let(:authorized_user) { public_project.owner }
  let(:resource) { public_workflow_version }
  let(:resource_class) { WorkflowVersion }

  describe "#index" do
    # The first version is linked to the project that we're the owner of, and should be visible
    # The third version is linked to a private project, which we don't own, and should be invisible
    let(:n_visible) { 1 }
    let(:private_resource) { private_workflow_version }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    it_behaves_like "is showable"
  end
end
