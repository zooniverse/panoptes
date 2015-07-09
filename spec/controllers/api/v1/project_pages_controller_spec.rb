require "spec_helper"

describe Api::V1::ProjectPagesController, type: :controller do
  let(:project) { create(:project) }
  let!(:pages) do
    [create(:project_page, project: project),
     create(:project_page, project: project, url_key: "faq"),
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

      describe "filter by language", :disabled do
        context "as a query param" do
          let(:filter_opts) { {language: "zh-tw"} }

          it 'should return matching pages' do
            expect(json_response[api_resource_name].map{ |p| p['language'] }).to all( eq("zh-tw") )
          end
        end

        context "using the Accept-Language Header" do
          let(:headers) { {"HTTP_ACCEPT_LANGUAGE" => "zh-tw"} }

          it 'should return matching pages' do
            expect(json_response[api_resource_name].map{ |p| p['language'] }).to all( eq("zh-tw") )
          end
        end

        context "when language is all" do
          let(:filter_opts) { {language: "all" } }

          it 'should not filter by language at all' do
            expect(json_response[api_resource_name].length).to eq(3)
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
        expect(json_response["meta"][api_resource_name]["first_href"]).to match(/projects\/[0-9]+\/pages/)
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
  end

  describe "#update" do
    let(:test_attr) { :content }
    let(:test_attr_value) { "dancer" }
    let(:update_params) do
      {
       project_id: project.id,
       project_pages: {
                       content: "dancer",
                      }
      }
    end

    it_behaves_like "is updatable"
  end

  describe "#destroy" do
    let(:delete_params) { {project_id: project.id} }

    it_behaves_like "is destructable"
  end
end
