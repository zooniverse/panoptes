require "spec_helper"

RSpec.describe Api::V1::SubjectWorkflowStatusesController, type: :controller do
  let(:api_resource_name) { 'subject_workflow_statuses' }
  let(:api_resource_attributes) do
    %w(id classifications_count retired_at retirement_reason created_at updated_at)
  end
  let(:api_resource_links) do
    %w(subject_workflow_statuses.workflow subject_workflow_statuses.subject)
  end

  let(:scopes) { %w(public) }
  let(:resource_class) { SubjectWorkflowStatus }

  describe "#index" do
    let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
    let!(:swcs) do
      workflow.subjects.map do |subject|
        create(:subject_workflow_status, subject: subject, workflow: workflow)
      end
    end
    let(:private_project) { create(:project_with_workflow, private: true) }
    let(:private_workflow) { private_project.workflows.first }
    let!(:private_resource) do
      create(:subject_workflow_status, workflow: private_workflow)
    end
    let(:authorized_user) { workflow.project.owner }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable"

    describe "filtering" do

      context "subject_id" do
        let(:subject_id) { swcs.last.subject_id }

        it "should return all the swc data for the supplied subject_id" do
          get :index, params: { workflow_id: workflow.id, subject_id: subject_id }
          resources = json_response[api_resource_name]
          expect(resources.length).to eq(1)
          expect(resources.first["links"]["subject"]).to eq(subject_id.to_s)
        end
      end

      context "workflow_id" do

        it "should return all the swc data for the supplied workflow_id" do
          get :index, params: { workflow_id: workflow.id }
          resources = json_response[api_resource_name]
          expect(resources.length).to eq(2)
          expected = resources.map { |r| r.dig("links", "workflow") }.uniq
          expect(expected).to match_array([ workflow.id.to_s ])
        end
      end
    end
  end

  describe "#show" do
    let(:resource) { create(:subject_workflow_status) }
    let(:authorized_user) { resource.project.owner }

    it_behaves_like "is showable"
  end
end
