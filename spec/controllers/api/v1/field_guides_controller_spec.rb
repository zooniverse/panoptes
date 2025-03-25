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
      let(:setup_field_guide) { }

      before(:each) do
        setup_field_guide
        default_request user_id: authorized_user.id, scopes: scopes
        get :index, params: filter_params
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

      context "by language" do
        let(:filter_params) { {language: "es-mx", project_id: project.id} }

        context "with no field guide" do
          it "should return not field guide" do
            expect(json_response[api_resource_name].length).to eq(0)
          end
        end

        context "with a field guide" do
          let(:setup_field_guide) do
            create(:field_guide, project: project, language: "es-mx")
          end

          it "should return field guide for es-mx" do
            resources = json_response[api_resource_name]
            expect(resources.length).to eq(1)
            resources.first["language"] == "es-mx"
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

    it_behaves_like "it syncs the resource translation strings", non_translatable_attributes_possible: false do
      let(:translated_klass_name) { FieldGuide.name }
      let(:translated_resource_id) { be_kind_of(Integer) }
      let(:translated_language) { create_params.dig(:field_guides, :language) }
      let(:controller_action) { :create }
      let(:translatable_action_params) { create_params }
    end
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

    it_behaves_like "it syncs the resource translation strings", non_translatable_attributes_possible: false do
      let(:translated_klass_name) { resource.class.name }
      let(:translated_resource_id) { resource.id }
      let(:translated_language) { resource.language }
      let(:controller_action) { :update }
      let(:translatable_action_params) { update_params.merge(id: resource.id) }
    end
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end
end
