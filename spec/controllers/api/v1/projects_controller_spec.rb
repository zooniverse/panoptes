require 'spec_helper'

describe Api::V1::ProjectsController, type: :controller do
  let!(:user) { create(:user) }
  let!(:projects) {create_list(:project_with_contents, 2, owner: user) }
  let(:authorized_user) { user }

  let(:api_resource_name) { "projects" }
  let(:api_resource_attributes) do
    ["id", "display_name", "classifications_count", "subjects_count",
     "updated_at", "created_at", "available_languages", "title",
     "description", "team_members", "guide", "science_case", "introduction", "migrated",
     "faq", "result", "education_content", "private", "live", "retired_subjects_count",
     "urls", "classifiers_count", "redirect" ]
  end
  let(:api_resource_links) do
    [ "projects.workflows",
      "projects.subject_sets",
      "projects.project_contents",
      "projects.project_roles",
      "projects.avatar",
      "projects.background",
      "projects.classifications_export",
      "projects.attached_images" ]
  end

  let(:scopes) { %w(public project) }
  let(:authorized_user) { user }
  let(:resource_class) { Project }
  let!(:private_resource) { create(:project, private: true) }
  let!(:beta_resource) { create(:project, beta_approved: true, launch_approved: false) }
  let!(:unapproved_resource) { create(:project, beta_approved: false, launch_approved: false) }

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

      describe "params" do
        let!(:project_owner) { create(:user) }
        let!(:new_project) do
          create(:full_project, display_name: "Non-test project", owner: project_owner)
        end

        before(:each) do
          get :index, index_options
        end

        describe "include avatar and background" do
          let(:index_options) { {include: 'avatar,background'} }

          it 'should include avatar' do
            expect(json_response["linked"]["avatars"].map{ |r| r['id'] })
              .to include(new_project.avatar.id.to_s)
          end

          it 'should include background' do
            expect(json_response["linked"]["backgrounds"].map{ |r| r['id'] })
              .to include(new_project.background.id.to_s)
          end
        end

        describe "include classifications_export" do
          let(:index_options) { {include: 'classifications_export'} }
          it 'should not allow classifications_export to be included' do
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        describe "filter by beta" do
          context "for beta projects" do
            let(:index_options) { { beta_approved: "true" } }

            it "should respond with the beta project" do
              ids = json_response["projects"].map{ |p| p["id"] }
              expect(Project.find(ids)).to include(beta_resource)
            end
          end

          context "for non-beta projects" do
            let(:index_options) { { beta_approved: "false" } }

            it "should not have beta projects" do
              ids = json_response["projects"].map{ |p| p["id"] }
              expect(Project.find(ids)).to_not include(beta_resource)
            end
          end
        end

        describe "filter by approved" do
          context "for unapproved projects" do
            let(:index_options) { { launch_approved: "false" } }

            it "should respond with the unapproved project" do
              ids = json_response["projects"].map{ |p| p["id"] }
              expect(Project.find(ids)).to include(unapproved_resource)
            end
          end

          context "for approved projects" do
            let(:index_options) { { launch_approved: "true" } }
            it "should not have unapproved projects" do
              ids = json_response["projects"].map{ |p| p["id"] }
              expect(Project.find(ids)).to_not include(unapproved_resource)
            end
          end
        end

        describe "filter by owner" do
          let(:index_options) { { owner: project_owner.login } }

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            owner_id = json_response[api_resource_name][0]['links']['owner']['id']
            expect(owner_id).to eq(new_project.owner.id.to_s)
          end
        end

        describe "filter by current_user_roles" do
          let(:index_options) { collab_acls; { current_user_roles: 'owner,collaborator' } }
          let(:collab_acls) do
            create(:access_control_list,
                   resource: beta_resource,
                   user_group: user.identity_group,
                   roles: ["viewer"])
            create(:access_control_list,
                   resource: new_project,
                   user_group: user.identity_group,
                   roles: ["collaborator"])
          end

          let(:response_ids) { json_response[api_resource_name].map{ |p| p['id'] } }

          it "should respond with 3 items" do
            expect(json_response[api_resource_name].length).to eq(3)
          end

          it 'should not have a project where the user has a different role' do
            expect(response_ids).to_not include(beta_resource.id.to_s)
          end

          it "should respond with the correct item" do
            expect(response_ids).to include(new_project.id.to_s, *projects.map(&:id).map(&:to_s))
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

        describe "filter by slug" do
          let(:index_options) { { slug: new_project.slug } }

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            project_slug = json_response[api_resource_name][0]['slug']
            expect(project_slug).to eq(new_project.slug)
          end
        end

        describe "filter by slug & owner" do
          let!(:filtered_project) do
            projects.first.owner = project_owner
            projects.first.save!
            projects.first
          end

          let(:index_options) do
            {owner: project_owner.login,
             slug: filtered_project.slug}
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
                     urls: [{label: "Twitter", url: "http://twitter.com/example"}],
                     configuration: {
                                     an_option: "a setting"
                                    },
                     beta_requested: true,
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

      describe "redirect option" do
        it_behaves_like "admin only option", :redirect, "http://example.com"
      end

      describe "approved option" do
        it_behaves_like "admin only option", :launch_approved, true
      end

      describe "approved option" do
        it_behaves_like "admin only option", :beta_approved, true
      end

      describe "create talk admin" do
        it 'should queue a talk admin create worker' do
          expect(TalkAdminCreateWorker).to receive(:perform_async).with(instance_of Fixnum)
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, create_params
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
          let(:contents) { Project.find(created_project_id).project_contents.first }

          it "should create an associated project_content model" do
            expect(contents).to_not be_nil
          end

          it 'should extract labels from the urls' do
            expect(Project.find(created_project_id).urls).to eq([{"label" => "0.label", "url" => "http://twitter.com/example"}])
          end


          it 'should save labels to contents' do
            expect(contents.url_labels).to eq({"0.label" => "Twitter"})
          end

          it 'should set the contents title do' do
            expect(contents.title).to eq('New Zoo')
          end

          it 'should set the description' do
            expect(contents.description).to eq('A new Zoo for you!')
          end

          it 'should set the language' do
            expect(contents.language).to eq('en')
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
                  name: "something_new",
                  education_content: "asdfasdf",
                  faq: "some other stuff",
                  result: "another string",
                  configuration: {
                                  an_option: "a setting"
                                 },
                  beta_requested: true,
                  live: true,
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
        ps[:projects][:launch_approved] = true
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

    context "live option" do
      context "when set false" do
        let!(:resource) {create(:project_with_contents, owner: user, beta_approved: true, launch_approved: true) }

        before(:each) do
          default_request scopes: scopes, user_id: authorized_user.id
        end

        it 'should set beta approved to false' do
          expect do
            ps = update_params
            ps[:admin] = true
            ps[:projects][:live] = false
            put :update, ps.merge(id: resource.id)
          end.to change{ Project.find(resource).beta_approved}.from(true).to(false)
        end

        it 'should set launch approved to false' do
          expect do
            ps = update_params
            ps[:admin] = true
            ps[:projects][:live] = false
            put :update, ps.merge(id: resource.id)
          end.to change{ Project.find(resource).launch_approved}.from(true).to(false)
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

  describe "#update_links" do
    let(:resource) { create(:project_with_contents, owner: authorized_user) }
    let(:resource_id) { :project_id }
    let(:test_attr) { :display_name }
    let(:test_relation_ids) { [ linked_resource.id.to_s ] }
    let(:copied_resource) { resource.reload.send(test_relation).first }

    describe "linking a workflow" do
      let!(:linked_resource) { create(:workflow, project: resource) }
      let(:test_relation) { :workflows }
      let(:expected_copies_count) { 1 }

      it_behaves_like "supports update_links"

      describe "linking a workflow that belongs to another project" do
        let!(:linked_resource) { create(:workflow) }

        it_behaves_like "supports update_links via a copy of the original" do

          it 'should have the same name' do
            update_via_links
            expect(copied_resource.display_name).to eq(linked_resource.display_name)
          end

          it 'should belong to the correct project' do
            update_via_links
            expect(copied_resource.project_id).to eq(resource.id)
          end
        end
      end
    end

    describe "linking a subject_set" do
      let(:linked_resource) { create(:subject_set_with_subjects, project: resource) }
      let(:test_relation) { :subject_sets }
      let(:expected_copies_count) { linked_resource.subjects.count }

      it_behaves_like "supports update_links"

      describe "linking a subject_set that belongs to another project" do
        let!(:linked_resource) { create(:subject_set_with_subjects) }

        it_behaves_like "supports update_links via a copy of the original" do

          it 'should have the same name' do
            update_via_links
            expect(copied_resource.display_name).to eq(linked_resource.display_name)
          end

          it 'should belong to the correct project' do
            update_via_links
            expect(copied_resource.project_id).to eq(resource.id)
          end

          it 'should create copies of every subject via set_member_subjects' do
            expect{ update_via_links }.to change { SetMemberSubject.count }.by(expected_copies_count)
          end
        end
      end
    end
  end

  describe "#create_export" do
    let(:resource) { create(:full_project, owner: user) }
    let(:resource_url) { /http:\/\/test.host\/api\/projects\/#{resource.id}\/classifications_export/ }
    let(:test_attr) { :type }
    let(:test_attr_value) { "project_classifications_export" }
    let(:new_resource) { Medium.find(created_instance_id(api_resource_name)) }
    let(:api_resource_name) { "media" }
    let(:api_resource_attributes) do
      ["id", "src", "created_at", "content_type", "media_type", "href"]
    end
    let(:api_resource_links) { [] }
    let(:resource_class) { Medium }

    let(:create_params) do
      params = {
                media: {
                        content_type: "text/csv",
                        metadata: { recipients: create_list(:user, 1).map(&:id) }
                       }
               }
      params.merge(project_id: resource.id, media_name: "classifications_exports")
    end

    it_behaves_like "is creatable", :create_export

    it 'should queue an export worker' do
      expect(ClassificationsDumpWorker).to receive(:perform_async).with(resource.id, an_instance_of(Fixnum))
      default_request scopes: scopes, user_id: user.id
      post :create_export, create_params
    end

    it 'should add the current user to the recipients list if none are specified' do
      params = create_params
      params[:media].delete(:metadata)
      default_request scopes: scopes, user_id: user.id
      post :create_export, params
      expect(resource.classifications_export.metadata).to include("recipients" => [authorized_user.id])
    end

    it 'should update an existing export if one exists' do
      params = create_params
      params[:media].delete(:metadata)
      export = create(:medium, linked: resource, type: "project_classifications_export", content_type: "text/csv", metadata: {})
      default_request scopes: scopes, user_id: user.id
      post :create_export, params
      export.reload
      expect(export.metadata).to include("recipients" => [authorized_user.id])
    end
  end

  describe "#destroy" do
    let(:resource) { create(:full_project, owner: user) }

    it_behaves_like "is destructable"
  end
end
