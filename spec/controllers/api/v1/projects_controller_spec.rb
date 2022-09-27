# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::ProjectsController, type: :controller do
  let(:user) { create(:user) }
  let(:projects) do
    create_list(:project_with_contents, 2, owner: user)
  end
  let(:project) { create(:project_with_contents, owner: user, state: 'paused') }

  let(:api_resource_name) { 'projects' }
  let(:api_resource_attributes) do
    %w[id display_name classifications_count subjects_count
       updated_at created_at available_languages title
       description introduction migrated private live
       retired_subjects_count urls classifiers_count redirect
       workflow_description tags experimental_tools
       completeness activity state mobile_friendly]
  end
  let(:api_resource_links) do
    ['projects.workflows',
     'projects.subject_sets',
     'projects.project_roles',
     'projects.avatar',
     'projects.background',
     'projects.classifications_export',
     'projects.subjects_export',
     'projects.attached_images']
  end

  let(:scopes) { %w[public project] }
  let(:authorized_user) { user }
  let(:resource_class) { Project }
  let(:private_resource) { create(:project, private: true) }
  let(:beta_resource) { create(:project, beta_approved: true, launch_approved: false) }
  let(:unapproved_resource) { create(:project, beta_approved: false, launch_approved: false) }
  let(:deactivated_resource) { create(:project, activated_state: :inactive) }

  describe '#index' do
    context 'when not logged in' do
      let(:authorized_user) { nil }
      let(:n_visible) { 2 }

      before do
        private_resource
        projects
      end

      it_behaves_like 'is indexable'
      it_behaves_like 'it has custom owner links', 'display_name'
      it_behaves_like 'it only lists active resources'
    end

    context 'when logged in' do
      describe 'custom owner links' do
        before do
          projects
          get :index
        end

        it_behaves_like 'it has custom owner links', 'display_name'
      end

      describe 'params' do
        let(:owner) { create(:user) }
        let(:new_project) do
          create(:full_project, display_name: 'Non-test project', owner: owner)
        end
        let(:resource) { new_project }
        let(:ids) { json_response['projects'].map { |p| p['id'] } }
        let(:index_request) do
          get :index, params: index_options
        end

        before do
          projects
        end

        describe 'search' do
          it_behaves_like 'filter by display_name'

          describe 'filter by display_name substring' do
            let(:index_options) { { search: resource.display_name[0..2] } }

            it 'responds with the most relevant item first' do
              index_request
              expect(json_response[api_resource_name].length).to eq(1)
            end
          end
        end

        describe 'cards only' do
          let(:index_options) { { cards: true } }
          let(:card_attrs) do
            %w[id display_name description slug redirect avatar_src links updated_at classifications_count launch_approved state completeness]
          end

          it 'returns only serialise the card data' do
            index_request
            card_keys = json_response[api_resource_name].map(&:keys).uniq.flatten
            expect(card_keys).to match_array(card_attrs)
          end
        end

        it_behaves_like 'indexable by tag' do
          let(:resource) { new_project }
          let(:second_resource) { beta_resource }
        end

        describe 'filtering' do
          let(:owner_resources) { [resource] }
          let(:collab_resource) { beta_resource }
          let(:viewer_resource) { private_resource }
          let(:authorized_user) { owner }

          it_behaves_like 'filters by owner'
          it_behaves_like 'filters by current user roles'

          context 'with the index request before' do
            before do
              index_request
            end

            describe 'beta' do
              context 'with beta projects' do
                let(:index_options) do
                  beta_resource
                  { beta_approved: 'true' }
                end

                it 'responds with the beta project' do
                  expect(Project.find(ids)).to include(beta_resource)
                end

                it 'returns projects in project rank order' do
                  ranked_ids = Project.where(beta_approved: true, private: false).rank(:beta_row_order).pluck(:id).map(&:to_s)
                  expect(ids).to match_array(ranked_ids)
                end
              end

              context 'with non-beta projects' do
                let(:index_options) { { beta_approved: 'false' } }

                it 'does not have beta projects' do
                  ids = json_response['projects'].map { |p| p['id'] }
                  expect(Project.find(ids)).not_to include(beta_resource)
                end
              end
            end

            describe 'approved' do
              context 'with unapproved projects' do
                let(:index_options) do
                  unapproved_resource
                  { launch_approved: 'false' }
                end

                it 'responds with the unapproved project' do
                  expect(Project.find(ids)).to include(unapproved_resource)
                end
              end

              context 'with approved projects' do
                let(:index_options) { { launch_approved: 'true' } }

                it 'does not have unapproved projects' do
                  expect(Project.find(ids)).not_to include(unapproved_resource)
                end

                it 'returns projects in project rank order' do
                  ranked_ids = Project.active.where(launch_approved: true, private: false).rank(:launched_row_order).pluck(:id).map(&:to_s)
                  expect(ids).to match_array(ranked_ids)
                end
              end
            end

            describe 'display_name' do
              let(:index_options) { { display_name: new_project.display_name } }

              it 'responds with 1 item' do
                expect(json_response[api_resource_name].length).to eq(1)
              end

              it 'responds with the correct item' do
                project_name = json_response[api_resource_name][0]['display_name']
                expect(project_name).to eq(new_project.display_name)
              end
            end

            describe 'slug' do
              let(:index_options) { { slug: new_project.slug } }

              it 'responds with 1 item' do
                expect(json_response[api_resource_name].length).to eq(1)
              end

              it 'responds with the correct item' do
                project_slug = json_response[api_resource_name][0]['slug']
                expect(project_slug).to eq(new_project.slug)
              end
            end

            describe 'slug & owner' do
              let!(:filtered_project) do
                projects.first.owner = owner
                projects.first.save!
                projects.first
              end

              let(:index_options) do
                { owner: owner.login, slug: filtered_project.slug }
              end

              it 'responds with 1 item' do
                expect(json_response[api_resource_name].length).to eq(1)
              end

              it 'responds with the correct item' do
                project_name = json_response[api_resource_name][0]['display_name']
                expect(project_name).to eq(filtered_project.display_name)
              end
            end

            describe 'filter by state' do
              let(:projects) do
                create_list(:project_with_contents, 2, owner: user).tap do |list|
                  list[0].paused!
                end
              end
              let(:filtered_project) { projects.first }
              let(:index_options) { { state: 'paused' } }

              it 'responds with 1 item' do
                expect(json_response[api_resource_name].length).to eq(1)
              end

              it 'responds with the correct item' do
                project_state = json_response[api_resource_name][0]['state']
                expect(project_state).to eq(filtered_project.state)
              end
            end
          end
        end
      end

      describe 'include params' do
        before do
          project
          get :index, params: { include: includes }
        end

        describe 'include avatar and background' do
          let(:project) do
            create(:full_project, display_name: 'Myproject')
          end
          let(:includes) { 'avatar,background' }

          it 'includes avatar' do
            expect(json_response['linked']['avatars'].map { |r| r['id'] })
              .to include(project.avatar.id.to_s)
          end

          it 'includes background' do
            expect(json_response['linked']['backgrounds'].map { |r| r['id'] })
              .to include(project.background.id.to_s)
          end
        end

        describe 'include classifications_export' do
          let(:includes) { 'classifications_export' }

          it 'does not allow classifications_export to be included' do
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when the serializer models are known' do
          let(:included_models) do
            %w[workflows subject_sets project_roles]
          end
          let(:includes) { included_models.join(',') }

          it 'includes the relations in the response as linked' do
            expect(json_response['linked'].keys).to match_array(included_models)
          end
        end

        context 'when the serializer model is polymorphic' do
          let(:includes) { 'owners' }

          it 'includes the owners in the response as linked' do
            expect(json_response['linked'].keys).to match_array([includes])
          end
        end

        context 'when the included model is invalid' do
          let(:includes) { 'unknown_model_plural' }

          it 'returns an error body in the response' do
            error_message = ':unknown_model_plural is not a valid include for Project'
            expect(response.body).to eq(json_error_message(error_message))
          end
        end
      end
    end
  end

  describe '#show' do
    let(:resource) { project }

    it_behaves_like 'is showable'

    it_behaves_like 'an api response' do
      before do
        get :show, params: { id: resource.id }
      end
    end
  end

  describe '#create' do
    let(:created_project_id) { created_instance_id('projects') }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { 'New Zoo' }
    let(:display_name) { test_attr_value }
    let(:owner_params) { nil }

    let(:default_create_params) do
      { projects: { display_name: display_name,
                    description: 'A new Zoo for you!',
                    primary_language: 'en',
                    workflow_description: 'some more text',
                    urls: [{ label: 'Twitter', url: 'http://twitter.com/example' }],
                    tags: %w[astro gastro],
                    configuration: {
                      an_option: 'a setting'
                    },
                    beta_requested: true,
                    private: true } }
    end

    let(:create_params) do
      ps = default_create_params
      if owner_params
        ps[:projects][:links] ||= {}
        ps[:projects][:links][:owner] = owner_params
      end
      ps
    end

    it_behaves_like 'it syncs the resource translation strings', non_translatable_attributes_possible: false do
      let(:translated_klass_name) { Project.name }
      let(:translated_resource_id) { be_kind_of(Integer) }
      let(:translated_language) { default_create_params.dig(:projects, :primary_language) }
      let(:controller_action) { :create }
      let(:translatable_action_params) { create_params }
    end

    describe 'redirect option' do
      it_behaves_like 'admin only option', :redirect, 'http://example.com'
    end

    describe 'launch approved option' do
      it_behaves_like 'admin only option', :launch_approved, true
    end

    describe 'beta approved option' do
      it_behaves_like 'admin only option', :beta_approved, true
    end

    describe 'launched_row_order_position option' do
      it_behaves_like 'admin only option', :launched_row_order_position, 10
    end

    describe 'beta_row_order_position option' do
      it_behaves_like 'admin only option', :beta_row_order_position, 10
    end

    describe 'experiemntal_tools option' do
      it_behaves_like 'admin only option', :experimental_tools, ['survey']
    end

    describe 'run_subject_set_completion_events attribute' do
      it_behaves_like 'admin only option', :run_subject_set_completion_events, true
    end

    describe 'create talk admin' do
      it 'queues a talk admin create worker' do
        expect(TalkAdminCreateWorker)
          .to receive(:perform_async)
          .with(be_kind_of(Integer))
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, params: create_params
      end
    end

    describe 'correct serializer configuration' do
      before do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, params: create_params
      end

      context 'without commas in the display name' do
        it 'returns the correct resource in the response' do
          expect(json_response['projects']).not_to be_empty
        end
      end

      context 'when the display name has commas in it' do
        let!(:display_name) { 'My parents, Steve McQueen, and God' }

        it 'returns a created response' do
          expect(json_response['projects']).not_to be_empty
        end
      end

      describe 'owner links' do
        it 'includes the link' do
          expect(json_response['linked']['owners']).not_to be_nil
        end
      end

      describe 'project contents' do
        let(:project) { Project.find(created_project_id) }

        it 'extracts labels from the urls' do
          expect(project.urls).to eq([{ 'label' => '0.label', 'url' => 'http://twitter.com/example' }])
          expect(project.url_labels).to eq({ '0.label' => 'Twitter' })
        end

        it 'sets the contents title do' do
          expect(project.title).to eq('New Zoo')
        end

        it 'sets the description' do
          expect(project.description).to eq('A new Zoo for you!')
        end
      end
    end

    describe 'tags' do
      let(:tags) { Tag.where(name: %w[astro gastro]) }

      def tag_request
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, params: create_params
      end

      context 'when the tags did not exist' do
        it 'create tag models for the project tags' do
          tag_request
          expect(tags.pluck(:tagged_resources_count)).to all(eq(1))
        end
      end

      context 'when the tags did exist' do
        it 'reuses existing tags' do
          create(:tag, name: 'astro')
          create(:tag, name: 'gastro')
          tag_request
          expect(tags.pluck(:tagged_resources_count)).to all(eq(2))
        end
      end

      it 'associate the tags with the project' do
        tag_request
        resource_id = json_response[api_resource_name][0]['id'].to_i
        expect(tags.flat_map { |t| t.projects.pluck(:id) }).to all(eq(resource_id))
      end
    end

    context 'when created with user as owner' do
      it_behaves_like 'is creatable'

      context 'with invalid create params' do
        it 'does not orphan an ACL instance when the model is invalid' do
          default_request scopes: scopes, user_id: authorized_user.id
          create_params[:projects] = create_params[:projects].except(:primary_language)
          expect { post :create, params: create_params }.not_to change(AccessControlList, :count)
        end
      end
    end

    context 'when created with specified user as owner' do
      context 'when user is the current user' do
        let(:owner_params) do
          {
            id: authorized_user.id.to_s,
            type: 'users'
          }
        end

        it_behaves_like 'is creatable'
      end

      context 'when user is not the current user' do
        let(:req) do
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, params: create_params
        end

        let(:owner_params) do
          user = create(:user)
          {
            id: user.id.to_s,
            type: 'users'
          }
        end

        it 'does not create a new project' do
          expect { req }.not_to change(Project, :count)
        end

        it 'returns 422' do
          req
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when creating with user_group as owner' do
      let(:owner) { create(:user_group) }
      let!(:membership) {
        create(:membership,
               state: :active,
               user: user,
               user_group: owner,
               roles: ['group_admin'])
      }

      let(:owner_params) do
        {
          id: owner.id.to_s,
          type: 'user_groups'
        }
      end

      it 'has the user group as its owner' do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, params: create_params
        project = Project.find(json_response['projects'][0]['id'])
        expect(project.owner).to eq(owner)
      end

      it_behaves_like 'is creatable'
    end
  end

  describe '#update' do
    let(:workflow) { create(:workflow) }
    let(:subject_set) { create(:subject_set) }
    let(:tutorial) do
      workflow = create(:workflow, project: resource)
      create(:tutorial, workflow: workflow)
    end
    let(:resource) { create(:project_with_contents, owner: authorized_user) }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { 'A Better Name' }
    let(:update_params) do
      {
        projects: {
          display_name: 'A Better Name',
          name: 'something_new',
          workflow_description: 'some more text',
          configuration: {
            an_option: 'a setting'
          },
          beta_requested: true,
          live: true,
          researcher_quote: 'this is such a great project',
          links: {
            workflows: [workflow.id.to_s],
            subject_sets: [subject_set.id.to_s]
          }
        }
      }
    end

    it_behaves_like 'is updatable'
    it_behaves_like 'has updatable tags' do
      let(:tag_array) { %w[astro gastro] }
      let(:tag_params) do
        { projects: { tags: tag_array }, id: resource.id }
      end
    end

    it_behaves_like 'it syncs the resource translation strings' do
      let(:translated_klass_name) { resource.class.name }
      let(:translated_resource_id) { resource.id }
      let(:translated_language) { resource.primary_language }
      let(:controller_action) { :update }
      let(:translatable_action_params) { update_params.merge(id: resource.id) }
      let(:non_translatable_action_params) { { id: resource.id, projects: { tags: ['cats'] } } }
    end

    describe 'launch_approved' do
      let(:ps) do
        ps = update_params
        ps[:admin] = true
        ps[:projects][:launch_approved] = true
        ps
      end

      before do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      context 'when the user is an admin' do
        let(:authorized_user) { create(:admin_user) }

        it 'updates the project' do
          put :update, params: ps.merge(id: resource.id)
          expect(response).to have_http_status(:ok)
        end

        it 'records the launch_date' do
          expect(resource.launch_date).to be_nil
          put :update, params: ps.merge(id: resource.id)
          expect(resource.reload.launch_date).not_to be_nil
        end

        it "does not record the launch_date if it's already been set" do
          resource.update_column(:launch_date, Time.zone.now)
          ld = resource.reload.launch_date
          put :update, params: ps.merge(id: resource.id)
          expect(resource.reload.launch_date).to eq(ld)
        end
      end

      context 'when the user is not an admin' do
        let(:authorized_user) { create(:user) }

        it 'does not update the project' do
          put :update, params: ps.merge(id: resource.id)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'with contents fields' do
      let(:params) do
        { projects: { description: 'SC', urls: [{ label: 'About', url: 'https://zooniverse.org/about' }] }, id: resource.id }
      end

      let(:project) { resource }

      before do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it 'updates the title' do
        params[:projects][test_attr] = test_attr_value
        put :update, params: params
        project.reload
        expect(project.title).to eq(test_attr_value)
      end

      it 'updates the description changes' do
        put :update, params: params
        project.reload
        expect(project.description).to eq('SC')
        expect(json_response['projects'][0]['description']).to eq('SC')
      end

      it 'extracts labels from the urls' do
        put :update, params: params
        project.reload
        expect(project.urls).to eq([{ 'label' => '0.label', 'url' => 'https://zooniverse.org/about' }])
      end

      it 'saves labels' do
        put :update, params: params
        project.reload
        expect(project.url_labels).to eq({ '0.label' => 'About' })
      end

      it 'touches the project resource to modify the cache_key / etag' do
        expect {
          put :update, params: params
        }.to change { resource.reload.updated_at }
      end
    end

    context 'with update_links' do
      let(:params) { update_params.merge(id: resource.id) }

      before do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      context 'when copying linked workflow' do
        it 'copies the workflow using the WorkflowCopier' do
          allow(WorkflowCopier).to receive(:copy).and_call_original
          put :update, params: params
          expect(WorkflowCopier).to have_received(:copy).with(workflow, resource.id)
        end

        it 'has a different id to the original workflow' do
          put :update, params: params
          expect(resource.workflows.first.id).not_to eq(workflow.id)
        end
      end

      context 'when copying linked subject_set' do
        before do
          put :update, params: params
        end

        it 'has the same name' do
          expect(resource.subject_sets.first.display_name).to eq(subject_set.display_name)
        end

        it 'has a different id' do
          expect(resource.subject_sets.first.id).not_to eq(subject_set.id)
        end
      end
    end
  end

  describe '#update_links' do
    let(:resource) { create(:project_with_contents, owner: authorized_user) }
    let(:resource_id) { :project_id }
    let(:test_attr) { :display_name }
    let(:test_relation_ids) { [linked_resource.id.to_s] }
    let(:copied_resource) { resource.reload.send(test_relation).first }

    describe 'linking a workflow' do
      let!(:linked_resource) { create(:workflow, project: resource) }
      let(:test_relation) { :workflows }
      let(:expected_copies_count) { 1 }

      it_behaves_like 'supports update_links'

      describe 'linking a workflow that belongs to another project' do
        let!(:linked_resource) { create(:workflow) }

        it_behaves_like 'supports update_links via a copy of the original' do
          it 'has a copy suffix added to the name' do
            update_via_links
            expect(copied_resource.display_name).to include("#{linked_resource.display_name} (copy:")
          end

          it 'belongs to the correct project' do
            update_via_links
            expect(copied_resource.project_id).to eq(resource.id)
          end
        end
      end
    end

    describe 'linking a subject_set' do
      let(:linked_resource) { create(:subject_set_with_subjects, project: resource) }
      let(:test_relation) { :subject_sets }
      let(:expected_copies_count) { linked_resource.subjects.count }

      it_behaves_like 'supports update_links'

      describe 'linking a subject_set that belongs to another project' do
        let!(:linked_resource) { create(:subject_set_with_subjects) }

        it_behaves_like 'supports update_links via a copy of the original' do
          it 'has the same name' do
            update_via_links
            expect(copied_resource.display_name).to eq(linked_resource.display_name)
          end

          it 'belongs to the correct project' do
            update_via_links
            expect(copied_resource.project_id).to eq(resource.id)
          end

          it 'creates copies of every subject via set_member_subjects' do
            expect { update_via_links }.to change(SetMemberSubject, :count).by(expected_copies_count)
          end
        end
      end
    end
  end

  context 'when creating exports' do
    let(:project) { create(:full_project, owner: user) }
    let(:test_attr) { :type }
    let(:new_resource) { Medium.find(created_instance_id(api_resource_name)) }
    let(:api_resource_name) { 'media' }
    let(:api_resource_attributes) do
      %w[id src created_at content_type media_type href]
    end
    let(:api_resource_links) { [] }
    let(:resource_class) { Medium }
    let(:content_type) { 'text/csv' }

    let(:create_params) do
      {
        project_id: project.id,
        media: {
          content_type: content_type,
          metadata: { recipients: create_list(:user, 1).map(&:id) }
        }
      }
    end

    describe '#create_classifications_export' do
      let(:resource_url) { %r{http://test.host/api/projects/#{project.id}/classifications_export} }
      let(:test_attr_value) { 'project_classifications_export' }

      it_behaves_like 'is creatable', :create_classifications_export
    end

    describe '#create_subjects_export' do
      let(:resource_url) { %r{http://test.host/api/projects/#{project.id}/subjects_export} }
      let(:test_attr_value) { 'project_subjects_export' }

      it_behaves_like 'is creatable', :create_subjects_export
    end

    describe '#create_workflows_export' do
      let(:resource_url) { %r{http://test.host/api/projects/#{project.id}/workflows_export} }
      let(:test_attr_value) { 'project_workflows_export' }

      it_behaves_like 'is creatable', :create_workflows_export
    end
  end

  describe '#destroy' do
    let(:resource) { create(:full_project, owner: user) }
    let(:instances_to_disable) { [resource] }

    it_behaves_like 'is deactivatable'
  end

  describe '#copy' do
    let(:resource) do
      create(:private_project, owner: authorized_user, configuration: { template: true })
    end
    let(:copy_params) { { project_id: resource.id } }
    let(:req) { post :copy, params: copy_params }
    let(:requesting_user) { authorized_user }

    before do
      resource
      default_request scopes: scopes, user_id: requesting_user.id
    end

    it 'calls the service operation' do
      operation_double = Projects::Copy.with(api_user: ApiUser.new(nil))
      allow(operation_double).to receive(:run!).and_return(resource)
      allow(Projects::Copy).to receive(:with).and_return(operation_double)
      req
      expect(operation_double).to have_received(:run!).with({ project: resource })
    end

    it 'return created response code' do
      req
      expect(response).to have_http_status(:created)
    end

    it 'serializes the created resource in the response body' do
      req
      expect(created_instance('projects')).not_to be_empty
    end

    it 'has no linked subject sets by default' do
      req
      linked_subject_set_ids = created_instance('projects').dig('links', 'subject_sets')
      expect(linked_subject_set_ids).to be_empty
    end

    context 'with a create_subject_set param' do
      let(:new_display_name) { 'Tropical F*** Storm' }
      let(:copy_params) { { project_id: resource.id, create_subject_set: new_display_name } }

      it 'calls the service operation' do
        operation_double = Projects::Copy.with(api_user: ApiUser.new(nil))
        allow(operation_double).to receive(:run!).and_return(resource)
        allow(Projects::Copy).to receive(:with).and_return(operation_double)
        req
        expect(operation_double).to have_received(:run!).with({ project: resource, create_subject_set: new_display_name })
      end
    end

    context 'with an uncopyable project' do
      before do
        resource.update(live: true)
      end

      it 'does not call the operation' do
        allow(Projects::Copy).to receive(:with)
        req
        expect(Projects::Copy).not_to have_received(:with)
      end

      it 'returns status code 405' do
        req
        expect(response).to have_http_status(:method_not_allowed)
      end

      it 'returns a useful error message' do
        req
        error_message = json_error_message(
          "Project with id #{resource.id} can not be copied, the project must not be 'live' and the configuration json must have the 'template' attribute set"
        )
        expect(response.body).to eq(error_message)
      end
    end

    context 'with an unauthorized user' do
      let(:unauthorized_user) { create(:user) }
      let(:requesting_user) { unauthorized_user }

      it 'does not call the operation' do
        allow(Projects::Copy).to receive(:with)
        req
        expect(Projects::Copy).not_to have_received(:with)
      end

      it 'returns status code 404' do
        req
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
