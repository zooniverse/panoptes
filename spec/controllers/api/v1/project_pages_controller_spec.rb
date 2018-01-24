require "spec_helper"

describe Api::V1::ProjectPagesController, type: :controller do
  let(:project) { create(:project) }
  let!(:pages) do
    [create(:project_page, project: project),
     create(:project_page, project: project, title: "FAQ", url_key: "faq"),
     create(:project_page, project: project, language: 'zh-tw'),
     create(:project_page)]
  end

  let(:scopes) { %w(public project) }

  let(:api_resource_name) { "project_pages" }
  let(:api_resource_attributes) do
    ["title", "created_at", "updated_at", "type", "content", "language", "url_key"]
  end

  let(:api_resource_links) { ["project_pages.project"] }

  let(:authorized_user) { project.owner }

  let(:resource) { pages.first }
  let(:resource_class) { ProjectPage }

  describe "#index" do
    let(:index_params) { {project_id: project.id} }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable", false

    describe "for a private project" do
      let(:private_project) { create(:project, private: true) }
      let!(:private_page) { create(:project_page, project: private_project) }

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        get :index, project_id: private_project.id
      end

      context "authorized user" do
        let(:authorized_user) { private_project.owner }

        it 'should return the page' do
          expect(json_response[api_resource_name][0]['id']).to eq(private_page.id.to_s)
        end
      end

      context "unauthorized user" do
        it 'should not return a page' do
          expect(json_response[api_resource_name]).to be_empty
        end
      end
    end

    describe "filter options" do
      let(:filter_opts) { {} }
      let(:headers) { {} }
      before(:each) do
        index_params.merge!(filter_opts)
        default_request scopes: scopes, user_id: authorized_user.id
        request.env.merge!(headers)
        get :index, index_params
      end

      describe "filter by url_key" do
        let(:filter_opts) { {url_key: "science_case"} }

        it 'should return matching pages' do
          expect(json_response[api_resource_name].map{ |p| p['url_key'] }).to all( eq("science_case") )
        end
      end

      describe "filter by language" do
        let(:taiwanese) { "zh-tw" }
        context "as a query param" do
          let(:filter_opts) { {language: taiwanese} }

          it 'should return matching pages' do
            resources = json_response[api_resource_name]
            returned_langs = resources.map{ |p| p['language'] }
            expect(returned_langs).to match_array([taiwanese])
          end
        end

        # Prefer the use of explicit query params to determine the
        # requesting language context for the meantime
        context "using the Accept-Language Header", :disabled do
          let(:headers) { {"HTTP_ACCEPT_LANGUAGE" => taiwanese} }

          it 'should return matching pages' do
            resources = json_response[api_resource_name]
            returned_langs = resources.map{ |p| p['language'] }
            expect(returned_langs).to all( eq(taiwanese) )
          end
        end

        context "when language is not set" do
          let(:filter_opts) { {} }

          it 'should return en default language project pages' do
            resources = json_response[api_resource_name]
            returned_langs = resources.map{ |p| p['language'] }
            expect(returned_langs).to match_array(["en", "en"])
          end
        end
      end
    end

    describe "paging" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        get :index, index_params
      end

      it 'should use correct paging links' do
        expect(json_response["meta"][api_resource_name]["first_href"]).to match(%r{projects/[0-9]+/pages})
      end
    end
  end

  describe "#show" do
    let(:show_params) { {project_id: project.id} }

    it_behaves_like "is showable"
  end

  describe "#create" do
    let(:test_attr) { :content }
    let(:test_attr_value) { "dancer" }
    let(:resource_url) { "http://test.host/api/projects/#{project.id}/pages/#{created_id}"}
    let(:create_params) do
      {
       project_id: project.id,
       project_pages: {
                       content: "dancer",
                       url_key: "whatevs",
                       language: "en-CA",
                       title: "Bester Pager"
                      }
      }
    end

    it_behaves_like "is creatable"

    it 'should set project from the project_id param' do
      default_request scopes: scopes, user_id: authorized_user.id
      post :create, create_params
      expect(json_response[api_resource_name][0]["links"]["project"]).to eq(project.id.to_s)
    end

    it_behaves_like "it syncs the resource translation strings" do
      let(:translated_klass_name) { ProjectPage.name }
      let(:translated_resource_id) { be_kind_of(Integer) }
      let(:translated_language) do
        create_params.dig(:project_pages, :language)
      end
      let(:controller_action) { :create }
      let(:controller_action_params) { create_params }
    end
  end

  describe "#update" do
    let(:test_attr) { :content }
    let(:test_attr_value) { "dancer" }
    let(:update_params) do
      {
       project_id: project.id,
       project_pages: {
                       content: "dancer"
                      }
      }
    end

    it_behaves_like "is updatable"

    it_behaves_like "it syncs the resource translation strings" do
      let(:translated_klass_name) { resource.class.name }
      let(:translated_resource_id) { resource.id }
      let(:translated_language) { resource.language }
      let(:controller_action) { :update }
      let(:controller_action_params) { update_params.merge(id: resource.id) }
    end
  end

  describe "#destroy" do
    let(:delete_params) { {project_id: project.id} }

    it_behaves_like "is destructable"
  end
end
