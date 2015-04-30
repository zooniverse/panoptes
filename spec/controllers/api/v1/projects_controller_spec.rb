require 'spec_helper'

describe Api::V1::ProjectsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:projects) {create_list(:project_with_contents, 2, owner: user, approved: true) }
  let(:authorized_user) { user }

  let(:api_resource_name) { "projects" }
  let(:api_resource_attributes) do
    ["id", "display_name", "classifications_count", "subjects_count",
     "updated_at", "created_at", "available_languages", "title", "avatar",
     "description", "team_members", "guide", "science_case", "introduction",
     "faq", "result", "education_content", "background_image", "private",
     "retired_subjects_count", "avatar", "background_image"]
  end
  let(:api_resource_links) do
    [ "projects.workflows",
     "projects.subject_sets",
     "projects.project_contents",
     "projects.project_roles" ]
  end

  let(:scopes) { %w(public project) }
  let(:authorized_user) { user }
  let(:resource_class) { Project }
  let!(:private_resource) { create(:project, private: true) }
  let!(:beta_resource) { create(:project, beta: true, approved: true) }
  let!(:unapproved_resource) { create(:project, beta: false, approved: false) }

  describe "when not logged in" do
    describe "#index" do
      let(:authorized_user) { nil }
      let(:n_visible) { 4 }
      it_behaves_like "is indexable"
      it_behaves_like "it has custom owner links"
    end
  end

  describe "a logged in user" do

    before(:each) do
      default_request(scopes: scopes, user_id: user.id)
    end

    describe "#index" do
      describe "custom owner links" do
        before(:each) do
          get :index
        end

        it_behaves_like "it has custom owner links"
      end

      describe "with no filtering" do
        let(:n_visible) { 4 }
        it_behaves_like "is indexable"
      end

      describe "filter params" do
        let!(:project_owner) { create(:user) }
        let!(:new_project) do
          create(:project, display_name: "Non-test project", owner: project_owner)
        end

        before(:each) do
          get :index, index_options
        end

        describe "filter by beta" do
          context "for beta projects" do
            let(:index_options) { { beta: "true" } }

            it "should respond with the beta project" do
              ids = json_response["projects"].map{ |p| p["id"] }
              expect(Project.find(ids)).to include(beta_resource)
            end
          end

          context "for non-beta projects" do
            let(:index_options) { { beta: "false" } }

            it "should not have beta projects" do
              ids = json_response["projects"].map{ |p| p["id"] }
              expect(Project.find(ids)).to_not include(beta_resource)
            end
          end
        end

        describe "filter by approved" do
          context "for unapproved projects" do
            let(:index_options) { { approved: "false" } }

            it "should respond with the unapproved project" do
              ids = json_response["projects"].map{ |p| p["id"] }
              expect(Project.find(ids)).to include(unapproved_resource)
            end
          end

          context "for approved projects" do
            let(:index_options) { { approved: "true" } }
            it "should not have unapproved projects" do
              ids = json_response["projects"].map{ |p| p["id"] }
              expect(Project.find(ids)).to_not include(unapproved_resource)
            end
          end


        end

        describe "filter by owner" do
          let(:index_options) { { owner: project_owner.identity_group.display_name } }

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            owner_id = json_response[api_resource_name][0]['links']['owner']['id']
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
            projects.first.owner = project_owner
            projects.first.save!
            projects.first
          end

          let(:index_options) do
            {owner: project_owner.identity_group.display_name,
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

      describe "include params" do
        before(:each) do
          get :index, { include: includes }
        end

        context "when the serializer models are known" do
          let(:included_models) do
            %w(workflows subject_sets project_contents project_roles)
          end
          let(:includes) { included_models.join(',') }

          it "should include the relations in the response as linked" do
            expect(json_response['linked'].keys).to match_array(included_models)
          end
        end

        context "when the serializer model is polymorphic" do
          let(:includes) { "owners" }

          it "should include the owners in the response as linked" do
            expect(json_response['linked'].keys).to match_array([includes])
          end
        end

        context "when the included model is invalid" do
          let(:includes) { "unknown_model_plural" }

          it "should return an error body in the response" do
            error_message = ":unknown_model_plural is not a valid include for Project"
            expect(response.body).to eq(json_error_message(error_message))
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
      let(:display_name) { test_attr_value }
      let(:owner_params) { nil }

      let(:default_create_params) do
        { projects: { display_name: display_name,
                     description: "A new Zoo for you!",
                     primary_language: 'en',
                     education_content: "asdfasdf",
                     faq: "some other stuff",
                     result: "another string",
                     avatar: "an avatar",
                     background_image: "and image",
                     configuration: {
                                     an_option: "a setting"
                                    },
                     beta: true,
                     private: true } }
      end

      let (:create_params) do
        ps = default_create_params
        if owner_params
          ps[:projects][:links] ||= Hash.new
          ps[:projects][:links][:owner] = owner_params
        end
        ps
      end

      describe "approved option" do
        before(:each) do
          ps = create_params
          ps[:admin] = true
          ps[:projects][:approved] = true
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, ps
        end

        context "when the user is an admin" do
          let(:authorized_user) { create(:admin_user) }
          it "should create the project" do
            expect(response).to have_http_status(:created)
          end
        end

        context "when the user is not an admin" do
          let(:authorized_user) { create(:user) }
          it "should not create the project" do
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      describe "correct serializer configuration" do
        before(:each) do
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, create_params
        end

        context "without commas in the display name" do

          it "should return the correct resource in the response" do
            expect(json_response["projects"]).to_not be_empty
          end
        end

        context "when the display name has commas in it" do
          let!(:display_name) { "My parents, Steve McQueen, and God" }

          it "should return a created response" do
            expect(json_response["projects"]).to_not be_empty
          end
        end

        describe "owner links" do
          it "should include the link" do
            expect(json_response['linked']['owners']).to_not be_nil
          end
        end

        describe "project contents" do

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
      end

      context "created with user as owner" do
        it_behaves_like "is creatable"

        context "with invalid create params" do

          it "should not orphan an ACL instance when the model is invalid" do
            default_request scopes: scopes, user_id: authorized_user.id
            create_params[:projects] = create_params[:projects].except(:primary_language)
            expect{ post :create, create_params }.not_to change{ AccessControlList.count }
          end
        end
      end

      context "created with specified user as owner" do
        context "user is the current user" do
          let(:owner_params) do
            {
             id: authorized_user.id.to_s,
             type: "users"
            }
          end

          it_behaves_like "is creatable"
        end

        context "user is not the current user" do
          let(:req) do
            default_request scopes: scopes, user_id: authorized_user.id
            post :create, create_params
          end


          let(:owner_params) do
            user = create(:user)
            {
              id: user.id.to_s,
                type: "users"
            }
          end

          it "should not create a new project" do
            expect{ req }.to_not change{Project.count}
          end

          it "should return 422" do
            req
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context "create with user_group as owner" do
        let(:owner) { create(:user_group) }
        let!(:membership) { create(:membership,
                                   state: :active,
                                   user: user,
                                   user_group: owner,
                                   roles: ["group_admin"]) }

        let(:owner_params) do
          {
           id: owner.id.to_s,
           type: "user_groups"
          }
        end

        it 'should have the user group as its owner' do
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, create_params
          project = Project.find(json_response['projects'][0]['id'])
          expect(project.owner).to eq(owner)
        end

        it_behaves_like "is creatable"
      end
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
                  beta: true,
                  name: "something_new",
                  education_content: "asdfasdf",
                  faq: "some other stuff",
                  result: "another string",
                  avatar: "an avatar",
                  background_image: "and image",
                  configuration: {
                                  an_option: "a setting"
                                 },
                  links: {
                          workflows: [workflow.id.to_s],
                          subject_sets: [subject_set.id.to_s]
                         }

                 }
      }
    end

    it_behaves_like "is updatable"

    describe "approved option" do
      before(:each) do
        ps = update_params
        ps[:admin] = true
        ps[:projects][:approved] = true
        default_request scopes: scopes, user_id: authorized_user.id
        put :update, ps.merge(id: resource.id)
      end

      context "when the user is an admin" do
        let(:authorized_user) { create(:admin_user) }
        it "should update the project" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when the user is not an admin" do
        let(:authorized_user) { create(:user) }
        it "should not update the project" do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "project_contents" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        params = update_params
        params[:projects][:science_case] = 'SC'
        params = params.merge(id: resource.id)
        put :update, params
      end

      it 'should update the default contents when the display_name is updated' do
        contents_title = resource.primary_content.reload
        contents_title = resource.primary_content.title
        expect(contents_title).to eq(test_attr_value)
      end

      it 'should update the default contents when the science case changes' do
        expect(json_response['projects'][0]['science_case']).to eq('SC')
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
          expect(resource.subject_sets.first.display_name).to eq(subject_set.display_name)
        end

        it 'should have a different id' do
          expect(resource.subject_sets.first.id).to_not eq(subject_set.id)
        end
      end
    end
  end

  describe "#destroy" do
    let(:resource) { create(:full_project, owner: user) }

    it_behaves_like "is destructable"
  end
end
