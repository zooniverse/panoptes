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
      let(:get_request) do
        get :index, filter_params
      end

      context "by project id" do
        let(:filter_params) { {project_id: project.id} }
        it "should return tutorial belong to project" do
          get_request
          aggregate_failures "project_id" do
            resources = json_response[api_resource_name]
            expect(resources.length).to eq(1)
            expect(resources.first["id"]).to eq(tutorials[0].id.to_s)
          end
        end
      end

      context "by workflow id" do
        let(:filter_params) { {workflow_id: workflow.id} }
        it "should return tutorial belong to workflow" do
          workflow_tutorial = create(:tutorial, project: project, workflows: [workflow])
          get_request
          aggregate_failures "workflow_id" do
            resources = json_response[api_resource_name]
            expect(resources.length).to eq(1)
            expect(resources.first["id"]).to eq(workflow_tutorial.id.to_s)
          end
        end
      end

      context "by kind" do
        let(:filter_params) { {kind: tutorials[0].kind} }
        it "should return tutorial belong to workflow" do
          tutorials[0].update! kind: "foo"
          get_request
          aggregate_failures "workflow_id" do
            resources = json_response[api_resource_name]
            expect(resources.length).to eq(1)
            expect(resources.first["id"]).to eq(tutorials[0].id.to_s)
          end
        end
      end

      context "by language" do
        let(:lang) { "es-mx" }
        let(:filter_params) { {language: lang} }

        it "should return tutorial for es-mx" do
          tutorials[0].update! language: lang
          get_request
          resources = json_response[api_resource_name]
          expect(resources.length).to eq(1)
          resources.first["language"] == lang
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
          display_name: "Asdf Asdf",
          links: {
            project: project.id.to_s,
            workflows: [workflow.id]
          },
          configuration: {
            an_option: 'a setting'
          }
        }
      }
    end

    it_behaves_like "is creatable"

    it_behaves_like "it syncs the resource translation strings", non_translatable_attributes_possible: false do
      let(:translated_klass_name) { Tutorial.name }
      let(:translated_resource_id) { be_kind_of(Integer) }
      let(:translated_language) { create_params.dig(:tutorials, :language) }
      let(:controller_action) { :create }
      let(:translatable_action_params) { create_params }
    end
  end

  describe "#update" do
    let(:test_attr) { :steps }
    let(:test_attr_value)  { [{"media" => "asdf", "content" => "asdf"}] }

    let(:update_params) do
      {
        tutorials: {
          steps: [{"media" => "asdf", "content" => "asdf"}]
        },
        configuration: {
          an_option: 'a setting'
        }
      }
    end

    it_behaves_like "is updatable"

    it_behaves_like "it syncs the resource translation strings" do
      let(:translated_klass_name) { resource.class.name }
      let(:translated_resource_id) { resource.id }
      let(:translated_language) { resource.language }
      let(:controller_action) { :update }
      let(:translatable_action_params) { update_params.merge(id: resource.id) }
      let(:non_translatable_action_params) { {id: resource.id, tutorials: {kind: "something"}} }
    end
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end
end
