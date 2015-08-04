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

    context "non-logged in users" do

      context "when the workflow does not have public aggregation" do
        let(:workflow) { create(:workflow) }

        it "should return an empty resource set" do
          get :index, workflow_id: workflow.id
          expect(json_response[api_resource_name].length).to eq(0)
        end
      end

      context "when the workflow has the public aggregation flag" do
        let(:workflow) { create(:workflow, aggregation: { public: true }) }
        let(:result_workflow_ids) do
          json_response[api_resource_name].map { |r| r["links"]["workflow"] }.uniq
        end

        it "should return all the aggregated data for the supplied workflow" do
          get :index, workflow_id: workflow.id
          expect(json_response[api_resource_name].length).to eq n_visible
        end

        context "when not supplying a workflow id" do

          it "should return all the public workflow resources" do
            get :index
            expect(result_workflow_ids).to match_array( [ "#{workflow.id}" ])
          end
        end

        context "when supplying just the non public workflow ids" do

          it "should return no results" do
            get :index, workflow_id: "#{private_resource.workflow_id}"
            expect(json_response[api_resource_name].length).to eq(0)
          end
        end

        context "when supplying a mix of public and non public workflow ids" do

          it "should only return the resources for the public workflow" do
            ids = [ workflow.id, private_resource.workflow_id ]
            get :index, workflow_ids: ids.join(",")
            expect(result_workflow_ids).to match_array( [ "#{workflow.id}" ])
          end
        end

        context "filtering on subject_id" do
          let(:subject_id) { "#{aggregations.last.subject_id}" }

          it "should return all the aggregated data for the supplied workflow" do
            get :index, workflow_id: workflow.id, subject_id: subject_id
            aggregate_failures "filtering" do
              resources = json_response[api_resource_name]
              expect(resources.length).to eq(1)
              aggregation = resources.first
              expect(aggregation["links"]["subject"]).to eq(subject_id)
            end
          end
        end
      end
    end
  end

  describe "#show" do
    let(:resource) { create(:aggregation) }
    let(:authorized_user) { resource.workflow.project.owner }

    it_behaves_like "is showable"

    context "non-logged in users" do

      context "when the workflow does not have public aggregation" do
        let(:workflow) { create(:workflow) }

        it "should return not_found" do
          get :show, id: resource.id
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the workflow has the public aggregation flag" do

        it "should return the aggregated resource with a public workflow" do
          resource.workflow.update_column(:aggregation, { public: true })
          get :show, id: resource.id
          aggregate_failures "public show" do
            expect(json_response[api_resource_name].length).to eq(1)
            expect(created_instance(api_resource_name)["id"]).to eq("#{resource.id}")
          end
        end
      end
    end
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
