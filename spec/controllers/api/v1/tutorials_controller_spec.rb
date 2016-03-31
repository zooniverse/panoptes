require "spec_helper"

describe Api::V1::TutorialsController, type: :controller do
  let(:private_project) { create(:project, private: true) }
  let(:project) { create(:project) }
  let(:workflow) { create(:workflow, project: project) }
  let!(:tutorials) do
    [ create(:tutorial, project: project),
      create(:tutorial),
      create(:tutorial, project: private_project) ]
  end

  let(:scopes) { %w(public project) }
  let(:api_resource_name) { "tutorials" }
  let(:api_resource_attributes) { %w(steps language) }
  let(:api_resource_links) { %w(tutorials.project tutorials.attached_images) }
  let(:authorized_user) { project.owner }
  let(:resource) { tutorials.first }
  let(:resource_class) { Tutorial }

  describe "#index" do
    let(:n_visible) { 2 }
    let(:private_resource) { tutorials[2] }

    it_behaves_like "is indexable"

    describe "filter_params" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
      end

      context "by project id" do
        let(:filter_params) { {project_id: project.id} }
        it "should return tutorial belong to project" do
          get :index, filter_params
          aggregate_failures "project_id" do
            expect(json_response["tutorials"].length).to eq(1)
            expect(json_response["tutorials"][0]["id"]).to eq(tutorials[0].id.to_s)
          end
        end
      end

      context "by workflow id" do
        let(:filter_params) { {workflow_id: workflow.id} }
        it "should return tutorial belong to workflow" do
          workflow_tutorial = create(:tutorial, project: project, workflows: [workflow])
          get :index, filter_params
          aggregate_failures "workflow_id" do
            expect(json_response["tutorials"].length).to eq(1)
            expect(json_response["tutorials"][0]["id"]).to eq(workflow_tutorial.id.to_s)
          end
        end
      end

      context "by kind" do
        let(:filter_params) { {kind: tutorials[0].kind} }
        it "should return tutorial belong to workflow" do
          tutorials[0].update! kind: "foo"
          get :index, filter_params
          aggregate_failures "workflow_id" do
            expect(json_response["tutorials"].length).to eq(1)
            expect(json_response["tutorials"][0]["id"]).to eq(tutorials[0].id.to_s)
          end
        end
      end
    end
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe "#create" do
    let(:test_attr) { :language }
    let(:test_attr_value)  { "es-mx" }
    let(:create_params) do
      {
        tutorials: {
          steps: [{media: "asdfasdf", content: 'asdklfajsdf'}, {media: 'asdklfjds;kajsdf', content: 'asdfklajsdf'}],
          language: 'es-mx',
          links: {
            project: project.id.to_s,
            workflows: [workflow.id]
          }
        }
      }
    end

    it_behaves_like "is creatable"
  end

  describe "#update" do
    let(:test_attr) { :steps }
    let(:test_attr_value)  { [{"media" => "asdf", "content" => "asdf"}] }

    let(:update_params) do
      {
        tutorials: {
          steps: [{"media" => "asdf", "content" => "asdf"}]
        }
      }
    end

    it_behaves_like "is updatable"
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end
end
