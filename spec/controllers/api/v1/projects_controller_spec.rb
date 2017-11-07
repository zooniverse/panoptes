require 'spec_helper'

describe Api::V1::ProjectsController, type: :controller do
  let(:user) { create(:user) }
  let(:projects) do
    create_list(:project_with_contents, 2, owner: user)
  end
  let(:project) { create(:project_with_contents, owner: user, state: "paused") }
  let(:authorized_user) { user }

  let(:api_resource_name) { "projects" }
  let(:api_resource_attributes) do
    ["id", "display_name", "classifications_count", "subjects_count",
     "updated_at", "created_at", "available_languages", "title",
     "description", "introduction", "migrated","private", "live",
     "retired_subjects_count", "urls", "classifiers_count", "redirect",
     "workflow_description", "tags", "experimental_tools",
     "completeness", "activity", "state", "mobile_friendly" ]
  end
  let(:api_resource_links) do
    [ "projects.workflows",
      "projects.subject_sets",
      "projects.project_contents",
      "projects.project_roles",
      "projects.avatar",
      "projects.background",
      "projects.classifications_export",
      "projects.aggregations_export",
      "projects.subjects_export",
      "projects.attached_images" ]
  end

  let(:scopes) { %w(public project) }
  let(:authorized_user) { user }
  let(:resource_class) { Project }
  let(:private_resource) { create(:project, private: true) }
  let(:beta_resource) { create(:project, beta_approved: true, launch_approved: false) }
  let(:unapproved_resource) { create(:project, beta_approved: false, launch_approved: false) }
  let(:deactivated_resource) { create(:project, activated_state: :inactive) }

  describe "#index" do
    context "not logged in" do
      let(:authorized_user) { nil }
      let(:n_visible) { 2 }

      before do
        private_resource
        projects
      end

      it_behaves_like "an indexable unauthenticated http cacheable response" do
        let(:action) { :index }
        let(:private_resource) do
          create(:project, owner: user, private: true)
        end
      end

      it_behaves_like "is indexable"
      it_behaves_like "it has custom owner links", "display_name"
      it_behaves_like "it only lists active resources"
    end

    context "logged in " do

      it_behaves_like "an indexable authenticated http cacheable response" do
        let(:action) { :index }
        let(:private_resource) do
          create(:project, owner: user, private: true)
        end
      end

      describe "custom owner links" do
        before(:each) do
          projects
          get :index
        end

        it_behaves_like "it has custom owner links", "display_name"
      end

      describe "params" do
        let(:owner) { create(:user) }
        let(:new_project) do
          create(:full_project, display_name: "Non-test project", owner: owner)
        end
        let(:resource) { new_project }
        let(:ids) { json_response["projects"].map{ |p| p["id"] } }
        let(:index_request) do
          get :index, index_options
        end

        before(:each) do
          projects
        end

        describe "search" do
          it_behaves_like "filter by display_name"

          describe "filter by display_name substring" do
            let(:index_options) { {search: resource.display_name[0..2]} }

            it "should respond with the most relevant item first" do
              index_request
              expect(json_response[api_resource_name].length).to eq(1)
            end
          end
        end

        describe "cards only" do
          let(:index_options) { { cards: true } }
          let(:card_attrs) do
            ["id", "display_name", "description", "slug", "redirect", "avatar_src", "links", "updated_at", "classifications_count"]
          end

          it "should return only serialise the card data" do
            index_request
            card_keys = json_response[api_resource_name].map(&:keys).uniq.flatten
            expect(card_keys).to match_array(card_attrs)
          end
        end

        it_behaves_like "taggable" do
          let(:resource) { new_project }
          let(:second_resource) { beta_resource }
        end

        describe "filtering" do
          let(:owner_resources) { [ resource ] }
          let(:collab_resource) { beta_resource }
          let(:viewer_resource) { private_resource }
          let(:authorized_user) { owner }

          it_behaves_like "filters by owner"
          it_behaves_like "filters by current user roles"

          context "with the index request before" do
            before do
              index_request
            end

            describe "beta" do
              context "for beta projects" do
                let(:index_options) do
                  beta_resource
                  { beta_approved: "true" }
                end

                it "should respond with the beta project" do
                  expect(Project.find(ids)).to include(beta_resource)
                end

                it 'should return projects in project rank order' do
                  ranked_ids = Project.where(beta_approved: true, private: false).rank(:beta_row_order).pluck(:id).map(&:to_s)
                  expect(ids).to match_array(ranked_ids)
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

            describe "approved" do
              context "for unapproved projects" do
                let(:index_options) do
                  unapproved_resource
                  { launch_approved: "false" }
                end

                it "should respond with the unapproved project" do
                  expect(Project.find(ids)).to include(unapproved_resource)
                end
              end

              context "for approved projects" do
                let(:index_options) { { launch_approved: "true" } }
                it "should not have unapproved projects" do
                  expect(Project.find(ids)).to_not include(unapproved_resource)
                end

                it 'should return projects in project rank order' do
                  ranked_ids = Project.active.where(launch_approved: true, private: false).rank(:launched_row_order).pluck(:id).map(&:to_s)
                  expect(ids).to match_array(ranked_ids)
                end
              end
            end

            describe "display_name" do
              let(:index_options) { { display_name: new_project.display_name } }

              it "should respond with 1 item" do
                expect(json_response[api_resource_name].length).to eq(1)
              end

              it "should respond with the correct item" do
                project_name = json_response[api_resource_name][0]['display_name']
                expect(project_name).to eq(new_project.display_name)
              end
            end

            describe "slug" do
              let(:index_options) { { slug: new_project.slug } }

              it "should respond with 1 item" do
                expect(json_response[api_resource_name].length).to eq(1)
              end

              it "should respond with the correct item" do
                project_slug = json_response[api_resource_name][0]['slug']
                expect(project_slug).to eq(new_project.slug)
              end
            end

            describe "slug & owner" do
              let!(:filtered_project) do
                projects.first.owner = owner
                projects.first.save!
                projects.first
              end

              let(:index_options) do
                {owner: owner.login, slug: filtered_project.slug}
              end

              it "should respond with 1 item" do
                expect(json_response[api_resource_name].length).to eq(1)
              end

              it "should respond with the correct item" do
                project_name = json_response[api_resource_name][0]['display_name']
                expect(project_name).to eq(filtered_project.display_name)
              end
            end

            describe "filter by state" do
              let(:projects) do
                create_list(:project_with_contents, 2, owner: user).tap do |list|
                  list[0].paused!
                end
              end
              let(:filtered_project) { projects.first }
              let(:index_options) { { state: "paused" } }

              it "should respond with 1 item" do
                expect(json_response[api_resource_name].length).to eq(1)
              end

              it "should respond with the correct item" do
                project_state = json_response[api_resource_name][0]['state']
                expect(project_state).to eq(filtered_project.state)
              end
            end
          end
        end
      end

      describe "include params" do
        before do
          project
          get :index, { include: includes }
        end

        describe "include avatar and background" do
          let(:project) do
            create(:full_project, display_name: "Myproject")
          end
          let(:includes) { 'avatar,background' }

          it 'should include avatar' do
            expect(json_response["linked"]["avatars"].map{ |r| r['id'] })
            .to include(project.avatar.id.to_s)
          end

          it 'should include background' do
            expect(json_response["linked"]["backgrounds"].map{ |r| r['id'] })
            .to include(project.background.id.to_s)
          end
        end

        describe "include classifications_export" do
          let(:includes) { 'classifications_export' }

          it 'should not allow classifications_export to be included' do
            expect(response).to have_http_status(:unprocessable_entity)
          end
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
  end

  describe "#show" do
    let(:resource) { project }

    it_behaves_like "is showable"

    it_behaves_like "an api response" do
      before do
        get :show, id: resource.id
      end
    end

    describe "http caching" do
      let(:action) { :show }
      let(:private_resource) do
        create(:project, owner: user, private: true)
      end
      let(:private_resource_id) { private_resource.id }
      let(:public_resource_id) { resource.id }

      it_behaves_like "a showable unauthenticated http cacheable response"
      it_behaves_like "a showable authenticated http cacheable response"
    end
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
                   workflow_description: "some more text",
                   urls: [{label: "Twitter", url: "http://twitter.com/example"}],
                   tags: ["astro", "gastro"],
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

    describe "launch approved option" do
      it_behaves_like "admin only option", :launch_approved, true
    end

    describe "beta approved option" do
      it_behaves_like "admin only option", :beta_approved, true
    end

    describe "launched_row_order_position option" do
      it_behaves_like "admin only option", :launched_row_order_position, 10
    end

    describe "beta_row_order_position option" do
      it_behaves_like "admin only option", :beta_row_order_position, 10
    end

    describe "experiemntal_tools option" do
      it_behaves_like "admin only option", :experimental_tools, ["survey"]
    end

    describe "create talk admin" do
      it 'should queue a talk admin create worker' do
        expect(TalkAdminCreateWorker)
          .to receive(:perform_async)
          .with(be_kind_of(Integer))
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

    describe "tags" do
      let(:tags) { Tag.where(name: ["astro", "gastro"]) }

      def tag_request
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
      end

      context "when the tags did not exist" do
        it 'should create tag models for the project tags' do
          tag_request
          expect(tags.pluck(:tagged_resources_count)).to all( eq(1) )
        end
      end

      context "when the tags did exist" do
        it 'should reuse existing tags' do
          create(:tag, name: "astro")
          create(:tag, name: "gastro")
          tag_request
          expect(tags.pluck(:tagged_resources_count)).to all( eq(2) )
        end
      end

      it 'should associate the tags with the project' do
        tag_request
        resource_id = json_response[api_resource_name][0]["id"].to_i
        expect(tags.flat_map{ |t| t.projects.pluck(:id) }).to all( eq(resource_id) )
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

  describe "#update" do
    let(:workflow) { create(:workflow) }
    let(:subject_set) { create(:subject_set) }
    let(:tutorial) do
      workflow = create(:workflow, project: resource)
      create(:tutorial, workflow: workflow)
    end
    let(:resource) { create(:project_with_contents, owner: authorized_user) }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "A Better Name" }
    let(:update_params) do
      {
        projects: {
          display_name: "A Better Name",
          name: "something_new",
          workflow_description: "some more text",
          configuration: {
            an_option: "a setting"
          },
          beta_requested: true,
          live: true,
          researcher_quote: "this is such a great project",
          links: {
            workflows: [workflow.id.to_s],
            subject_sets: [subject_set.id.to_s]
          }
        }
      }
    end

    it_behaves_like "is updatable"

    describe "update tags" do
      let(:tags) { ["astro", "gastro"] }
      let(:tag_params) do
        { projects: { tags: tags }, id: resource.id }
      end

      def tag_update
        default_request scopes: scopes, user_id: authorized_user.id
        put :update, tag_params
      end

      it 'should remove all previous tags' do
        create(:tag, name: "GONE", resource: resource)
        tag_update
        resource.reload
        expect(resource.tags.pluck(:name)).to_not include("GONE")
      end

      it 'should update with new tags' do
        tag_update
        resource.reload
        expect(resource.tags.pluck(:name)).to match_array(tags)
      end

      it "should touch the project resource to modify the cache_key / etag" do
        expect {
          tag_update
        }.to change { resource.reload.updated_at }
      end
    end

    describe "launch_approved" do
      let(:ps) do
        ps = update_params
        ps[:admin] = true
        ps[:projects][:launch_approved] = true
        ps
      end

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      context "when the user is an admin" do
        let(:authorized_user) { create(:admin_user) }

        it "should update the project" do
          put :update, ps.merge(id: resource.id)
          expect(response).to have_http_status(:ok)
        end

        it "should record the launch_date" do
          expect(resource.launch_date).to be_nil
          put :update, ps.merge(id: resource.id)
          expect(resource.reload.launch_date).not_to be_nil
        end

        it "should not record the launch_date if it's already been set" do
          resource.update_column(:launch_date, Time.zone.now)
          ld = resource.reload.launch_date
          put :update, ps.merge(id: resource.id)
          expect(resource.reload.launch_date).to eq(ld)
        end
      end

      context "when the user is not an admin" do
        let(:authorized_user) { create(:user) }
        it "should not update the project" do
          put :update, ps.merge(id: resource.id)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "project_contents" do
      let(:params) do
        { projects: { description: 'SC' }, id: resource.id }
      end

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it 'should update the default contents when the display_name is updated' do
        params[:projects][test_attr] = test_attr_value
        put :update, params
        contents_title = resource.primary_content.reload
        contents_title = resource.primary_content.title
        expect(contents_title).to eq(test_attr_value)
      end

      it 'should update the default contents when the description changes' do
        put :update, params
        expect(json_response['projects'][0]['description']).to eq('SC')
      end

      it "should touch the project resource to modify the cache_key / etag" do
        expect {
          put :update, params
        }.to change { resource.reload.updated_at }
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

  context "creating exports" do
    let(:project) { create(:full_project, owner: user) }
    let(:test_attr) { :type }
    let(:new_resource) { Medium.find(created_instance_id(api_resource_name)) }
    let(:api_resource_name) { "media" }
    let(:api_resource_attributes) do
      ["id", "src", "created_at", "content_type", "media_type", "href"]
    end
    let(:api_resource_links) { [] }
    let(:resource_class) { Medium }
    let(:content_type) { "text/csv" }

    let(:create_params) do
      params = {
        project_id: project.id,
        media: {
          content_type: content_type,
          metadata: { recipients: create_list(:user, 1).map(&:id) }
        }
      }
    end

    describe "#create_classifications_export" do
      let(:resource_url) { /http:\/\/test.host\/api\/projects\/#{project.id}\/classifications_export/ }
      let(:test_attr_value) { "project_classifications_export" }

      it_behaves_like "is creatable", :create_classifications_export
    end

    describe "#create_aggregations_export" do
      let(:resource_url) { /http:\/\/test.host\/api\/projects\/#{project.id}\/aggregations_export/ }
      let(:test_attr_value) { "project_aggregations_export" }
      let(:content_type) { "application/x-gzip" }

      it_behaves_like "is creatable", :create_aggregations_export
    end

    describe "#create_subjects_export" do
      let(:resource_url) { /http:\/\/test.host\/api\/projects\/#{project.id}\/subjects_export/ }
      let(:test_attr_value) { "project_subjects_export" }

      it_behaves_like "is creatable", :create_subjects_export
    end

    describe "#create_workflows_export" do
      let(:resource_url) { /http:\/\/test.host\/api\/projects\/#{project.id}\/workflows_export/ }
      let(:test_attr_value) { "project_workflows_export" }

      it_behaves_like "is creatable", :create_workflows_export
    end

    describe "#create_workflow_contents_export" do
      let(:resource_url) { /http:\/\/test.host\/api\/projects\/#{project.id}\/workflow_contents_export/ }
      let(:test_attr_value) { "project_workflow_contents_export" }

      it_behaves_like "is creatable", :create_workflow_contents_export
    end
  end

  describe "#destroy" do
    let(:resource) { create(:full_project, owner: user) }
    let(:instances_to_disable) { [resource] }

    it_behaves_like "is deactivatable"
  end

  describe "versioning" do
    let(:resource) { project }
    let!(:existing_versions) { resource.versions.length }
    let(:num_times) { 11 }
    let(:update_proc) { Proc.new { |resource, n| resource.update!(live: (n % 2 == 0)) } }
    let(:resource_param) { :project_id }

    it_behaves_like "a versioned resource"
  end
end
