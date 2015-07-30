require "spec_helper"

RSpec.describe Api::V1::AggregationsController, type: :controller do
  let(:api_resource_name) { 'aggregations' }

  let(:api_resource_attributes) { %w(id created_at updated_at aggregation) }
  let(:api_resource_links) { %w(aggregations.workflow aggregations.subject) }

  let(:scopes) { %w(public project) }
  let(:resource_class) { Aggregation }

  describe "#index" do
    let(:workflow) { create(:workflow) }
    let!(:aggregations) { create_list(:aggregation, 2, workflow: workflow) }
    let!(:private_resource) { create(:aggregation) }
    let(:authorized_user) { workflow.project.owner }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable"

    context "non-logged in users", :focus do
      before(:each) do
        get :index, workflow_id: workflow.id
      end

      context "when the workflow does not have public aggregation" do
        let(:workflow) { create(:workflow) }

        it "should return unauthorized" do
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when the workflow has the public aggregation flag" do
        let(:workflow) { create(:workflow, aggregation: { public: true }) }

        it "should return all the workflow data" do
          get :index, workflow_id: workflow.id
          expect(json_response[api_resource_name].length).to eq n_visible
        end
      end
    end
  end

  describe "#show" do
    let(:resource) { create(:aggregation) }
    let(:authorized_user) { resource.workflow.project.owner }

    it_behaves_like "is showable"
  end

  describe "create" do
    let(:workflow) { create(:workflow_with_subjects) }
    let(:subject) { workflow.subject_sets.first.subjects.first }
    let(:authorized_user) { workflow.project.owner }
    let(:test_attr) { :aggregation }
    let(:test_attr_value) { { "something" => "HERE",
                              "workflow_version" => "1.1" } }

    let(:create_params) do
      { aggregations:
          {
            aggregation: test_attr_value,
            links: {
              subject: subject.id.to_s,
              workflow: workflow.id.to_s
            }
          }
      }
    end

    it_behaves_like "is creatable"
  end

  describe '#update' do
    let(:workflow) { create(:workflow_with_subjects) }
    let(:subject) { workflow.subject_sets.first.subjects.first }
    let(:authorized_user) { resource.workflow.project.owner }
    let(:resource) { create(:aggregation, workflow: workflow) }
    let(:aggregation_results) do
      { "mean" => "1",
        "std" => "1",
        "count" => ["1","1","1"],
        "workflow_version" => "1.1" }
    end
    let(:test_attr) { :aggregation }
    let(:test_attr_value) { aggregation_results }
    let(:test_relation) { :subject }
    let(:test_relation_ids) { [ subject.id ] }
    let(:update_params) do
      { aggregations:
          {
            aggregation: aggregation_results,
            links: {
              subject: subject.id.to_s,
              workflow: workflow.id.to_s
            }
          }
      }
    end

    it_behaves_like "is updatable"

    it_behaves_like "has updatable links"
  end
end
