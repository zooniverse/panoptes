require 'spec_helper'

describe Api::V1::ProjectsController, type: :controller do
  let!(:user) {
    create(:user)
  }

  let!(:projects) {
    projects = create_list(:project_with_contents, 2, owner: user)
  }

  let(:api_resource_name) { "projects" }
  let(:api_resource_attributes) do
    ["id", "name", "display_name", "classifications_count", "subjects_count",
     "updated_at", "created_at", "available_languages", "title", "avatar",
     "description", "team_members", "guide", "science_case", "introduction",
     "background_image"]
  end
  let(:api_resource_links) do
    [ "projects.owner",
      "projects.workflows",
      "projects.subject_sets",
      "projects.project_contents",
      "projects.project_roles" ]
  end

  let(:scopes) { %w(public project) }
  let(:authorized_user) { user }
  let(:resource_class) { Project }

  describe "when not logged in" do

    describe "#index" do

      before(:each) do
        get :index
      end

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should have 2 items by default" do
        expect(json_response[api_resource_name].length).to eq(2)
      end

      it_behaves_like "an api response"
    end
  end

  describe "a logged in user" do

    before(:each) do
      default_request(scopes: scopes, user_id: user.id)
    end
    
    describe "#index" do

      describe "with no filtering" do

        before(:each) do
          get :index
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should have 2 items by default" do
          expect(json_response[api_resource_name].length).to eq(2)
        end

        it_behaves_like "an api response"
      end

      describe "filter params" do
        let!(:project_owner) { create(:user) }
        let!(:new_project) do
          create(:project, display_name: "Non-test project", owner: project_owner)
        end

        before(:each) do
          get :index, index_options
        end

        describe "filter by owner" do
          let(:index_options) { { owner: project_owner.owner_uniq_name } }

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            owner_id = json_response[api_resource_name][0]['links']['owner']
            expect(owner_id).to eq(new_project.owner.id.to_s)
          end
        end

        describe "filter by display_name" do
          let(:index_options) { { display_name: new_project.display_name } }

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            project_name = json_response[api_resource_name][0]['display_name']
            expect(project_name).to eq(new_project.display_name)
          end
        end

        describe "filter by display_name & owner" do
          let!(:filtered_project) do
            projects.first.update_attribute(:owner_id, project_owner.id)
            projects.first
          end
          let(:index_options) do
            {owner: project_owner.owner_uniq_name,
             display_name: filtered_project.display_name}
          end

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            project_name = json_response[api_resource_name][0]['display_name']
            expect(project_name).to eq(filtered_project.display_name)
          end
        end
      end
    end

    describe "#show" do
      before(:each) do
        get :show, id: projects.first.id
      end

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should return the only requested project" do
        expect(json_response[api_resource_name].length).to eq(1)
        expect(json_response[api_resource_name][0]['id']).to eq(projects.first.id.to_s)
      end

      it_behaves_like "an api response"
    end

    describe "#create" do
      let(:created_project_id) { created_instance_id("projects") }
      let(:test_attr) { :display_name }
      let(:test_attr_value) { "New Zoo" }

      let(:create_params) do
        { projects: {display_name: "New Zoo",
                     description: "A new Zoo for you!",
                     name: "new_zoo",
                     primary_language: 'en' } }
      end

      describe "project contents" do
        before(:each) do
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, create_params
        end
        
        it "should create an associated project_content model" do
          expect(Project.find(created_project_id)
                 .project_contents.first).to_not be_nil
        end

        it 'should set the contents title do' do
          expect(Project.find(created_project_id)
                 .project_contents.first.title).to eq('New Zoo')
        end

        it 'should set the description' do
          expect(Project.find(created_project_id)
                 .project_contents.first.description).to eq('A new Zoo for you!')
        end

        it 'should set the language' do
          expect(Project.find(created_project_id)
                 .project_contents.first.language).to eq('en')
        end
      end
      
      it_behaves_like "is creatable"
    end
  end

  describe "#update" do
    let(:workflow) { create(:workflow) }
    let(:subject_set) { create(:subject_set) }
    let(:resource) { create(:project_with_contents, owner: authorized_user) }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "A Better Name" }
    let(:update_params) do
      {
       projects: {
                  display_name: "A Better Name",
                  name: "something_new",
                  links: {
                          workflows: [workflow.id.to_s],
                          subject_sets: [subject_set.id.to_s]
                         }
                  
                 }
      }
    end

    it_behaves_like "is updatable"

    context "project_contents" do
      it 'should update the default contents when the display_name or description is updated' do
        default_request scopes: scopes, user_id: authorized_user.id
        params = update_params.merge(id: resource.id)
        put :update, params

        contents_title = resource.project_contents
          .where(language: resource.primary_language).first.title
        
        expect(contents_title).to eq(test_attr_value)
      end
    end

    context "update_links" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        params = update_params.merge(id: resource.id)
        put :update, params
      end

      context "copy linked workflow" do
        it 'should have the same tasks workflow' do
          expect(resource.workflows.first.tasks).to eq(workflow.tasks)
        end
        

        it 'should have a different id' do
          expect(resource.workflows.first.id).to_not eq(workflow.id)
        end
      end

      context "copy linked subject_set" do
        it 'should have the same name' do
          expect(resource.subject_sets.first.name).to eq(subject_set.name)
        end

        it 'should have a differen id' do
          expect(resource.subject_sets.first.id).to_not eq(subject_set.id)
        end
      end
    end
  end
  
  describe "#destroy" do
    let(:resource) { projects.first }

    it_behaves_like "is destructable"
  end
end
