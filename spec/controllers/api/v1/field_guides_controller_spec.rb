require "spec_helper"

describe Api::V1::FieldGuidesController, type: :controller do
  let(:private_project) { create(:project, private: true) }
  let(:project) { create(:project) }
  let!(:field_guides) do
    [ create(:field_guide, project: project),
      create(:field_guide),
      create(:field_guide, project: private_project) ]
  end

  let(:scopes) { %w(public project) }
  let(:api_resource_name) { "field_guides" }
  let(:api_resource_attributes) { %w(items language) }
  let(:api_resource_links) { %w(field_guides.project field_guides.attached_images) }
  let(:authorized_user) { project.owner }
  let(:resource) { field_guides.first }
  let(:resource_class) { FieldGuide }

  describe "#index" do
    let(:n_visible) { 2 }
    let(:private_resource) { field_guides.last }

    it_behaves_like "is indexable"

    describe "filter_params" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        get :index, filter_params
      end

      context "by project id" do
        let(:filter_params) { {project_id: project.id} }
        it "should return field guide belong to project" do
          aggregate_failures "project_id" do
            expect(json_response[api_resource_name].length).to eq(1)
            expect(created_instance_id(api_resource_name)).to eq(field_guides.first.id.to_s)
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
    let(:lang) { "en-au" }
    let(:test_attr_value)  { lang }
    let(:create_params) do
      {
        field_guides: {
          items: [
            {icon: "789", title: "Stuff", content: 'things'},
            {icon: "897", title: "More things", content: 'other stuff'}
          ],
          language: lang,
          links: {
            project: project.id.to_s
          }
        }
      }
    end

    it_behaves_like "is creatable"
  end

  describe "#update" do
    let(:test_attr) { :items }
    let(:test_attr_value) do
      [{"icon" => "789", "title" => "Stuff", "content" => 'things'}]
    end

    let(:update_params) do
      {
        field_guides: {
          items: test_attr_value
        }
      }
    end

    it_behaves_like "is updatable"
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end
end
