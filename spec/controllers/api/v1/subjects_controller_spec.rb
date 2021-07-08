require 'spec_helper'

describe Api::V1::SubjectsController, type: :controller do
  let(:workflow) { create(:workflow_with_subject_sets) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:sms) { create_list(:set_member_subject, 2, subject_set: subject_set) }
  let!(:subjects) { sms.map(&:subject) }
  let(:user) { create(:user) }
  let(:scopes) { %w(subject) }
  let(:resource_class) { Subject }
  let(:authorized_user) { user }
  let(:project) { create(:project, owner: user) }
  let(:api_resource_name) { "subjects" }
  let(:api_resource_attributes) do
    [ "id", "metadata", "locations", "zooniverse_id", "created_at", "updated_at" ]
  end
  let(:api_resource_links) do
    [ "subjects.project","subjects.collections", "subjects.subject_sets" ]
  end

  describe "#index" do
    context "logged out user" do

      it_behaves_like "an indexable unauthenticated http cacheable response" do
        let(:action) { :index }
        let(:private_resource) do
          project = create(:project, private: true) do |p|
            p.owner = user
          end
          create(:subject, project: project)
        end
      end

      describe "filtering" do
        let(:expected_filtered_ids) { formated_string_ids(filterable_resources) }

        context "with collection has_many" do
          let(:filterable_resources) do
            create_list(:collection_with_subjects, 2).first.subjects
          end

          it_behaves_like 'has many filterable', :collections
        end

        context "with subject_sets has_many" do
          before do
            create(:subject_set_with_subjects)
          end

          let(:filterable_resources) do
            subject_set.subjects
          end

          it_behaves_like 'has many filterable', :subject_sets
        end
      end

      context "without any sort" do
        before(:each) do
          get :index
        end

        it_behaves_like "an api response"

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should return a page of 2 objects" do
          expect(json_response[api_resource_name].length).to eq(2)
        end

        describe "optional context attributes" do
          let(:attr_field_set) do
            json_response[api_resource_name].map { |s| s.has_key?(optional_attr) }.uniq
          end

          %w(retired already_seen finished_workflow favorite).each do |attr|
            let(:optional_attr) { attr }

            it "should not serialize the #{attr} attribute" do
              expect(attr_field_set).to match([false])
            end
          end
        end
      end

      context "a queued request" do
        let!(:sms) { create_list(:set_member_subject, 2, subject_set: subject_set) }
        let(:request_params) { { sort: 'queued', workflow_id: workflow.id.to_s } }
        let(:api_resource_links) { [] }

        context "with queued subjects" do

          it_behaves_like "is not a http cacheable response" do
            let(:action) { :queued }
            let(:params) { { workflow_id: workflow.id } }
          end

          context "when firing the request before the test" do
            before(:each) do
              get :index, request_params
            end

            it "should return 200" do
              expect(response.status).to eq(200)
            end

            it 'should return a page of 2 objects' do
              expect(json_response[api_resource_name].length).to eq(2)
            end

            it_behaves_like "an api response"

            context "with extraneous filtering params" do
              let!(:request_params) do
                { sort: 'queued', workflow_id: workflow.id.to_s, project_id: "1", collection_id: "1" }
              end

              it "should return 200" do
                expect(response.status).to eq(200)
              end

              it 'should return a page of 2 objects' do
                expect(json_response[api_resource_name].length).to eq(2)
              end
            end
          end

          context "with no data to select from" do
            before do
              allow_any_instance_of(Workflow)
              .to receive(:set_member_subjects)
              .and_return([])
            end

            it 'should return an error message', :aggregate_failures do
              get :index, request_params
              expect(response.status).to eq(404)
              error_body = "No data available for selection"
              expect(response.body).to eq(json_error_message(error_body))
            end
          end
        end
      end
    end

    context "logged in user" do
      before(:each) do
        default_request user_id: user.id, scopes: scopes
      end

      it_behaves_like "an indexable authenticated http cacheable response" do
        let(:action) { :index }
        let(:private_resource) do
          project = create(:project, private: true) do |p|
            p.owner = user
          end
          create(:subject, project: project)
        end
      end

      context "without any sort" do
        before(:each) do
          get :index
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should return a page of 2 objects" do
          expect(json_response[api_resource_name].length).to eq(2)
        end

        it_behaves_like "an api response"
      end

      context "a queued request" do
        let!(:sms) { create_list(:set_member_subject, 2, subject_set: subject_set) }
        let(:request_params) { { sort: 'queued', workflow_id: workflow.id.to_s } }
        let(:api_resource_links) { [] }

        it 'should pass the selector context to the serializer' do
          formatted_context = {}
          context_double = instance_double("Subjects::SelectorContext")
          allow(context_double).to receive(:format).and_return(formatted_context)
          allow(Subjects::SelectorContext)
            .to receive(:new)
            .and_return(context_double)
          expect(SubjectSelectorSerializer)
            .to receive(:page)
            .with(anything, anything, formatted_context)
          get :index, request_params
        end

        context "with subjects" do
          it "should return 200" do
            get :index, request_params
            expect(response.status).to eq(200)
          end

          it 'should return a page of 2 objects' do
            get :index, request_params
            expect(json_response[api_resource_name].length).to eq(2)
          end

          it 'should return already_seen as false' do
            get :index, request_params
            already_seen = json_response["subjects"].map{ |s| s['already_seen']}
            expect(already_seen).to all( be false )
          end

          it 'should return finished_workflow as false' do
            get :index, request_params
            seen_all = json_response["subjects"].map{ |s| s['finished_workflow']}
            expect(seen_all).to all( be false )
          end

          it 'should return retired as false' do
            get :index, request_params
            retired = json_response["subjects"].map{ |s| s['retired']}
            expect(retired).to all( be false )
          end

          it_behaves_like "an api response" do
            before { get :index, request_params }
          end
        end

        context "user has classified all subjects in the workflow" do
          let!(:seen_subjects) do
            create :classification, user: user, workflow: workflow, subjects: subjects
            create(:user_seen_subject,
                   user: user,
                   workflow: workflow,
                   subject_ids: subjects.map(&:id))
          end

          it 'should return already_seen true for each subject' do
            get :index, request_params
            already_seen = json_response["subjects"].map{ |s| s['already_seen']}
            expect(already_seen).to all( be true )
          end

          it 'should return finished_workflow as false' do
            get :index, request_params
            seen_all = json_response["subjects"].map{ |s| s['finished_workflow']}
            expect(seen_all).to all( be false )
          end

          it 'should return user_has_finished_workflow as true for each subject' do
            get :index, request_params
            seen_all = json_response["subjects"].map{ |s| s['user_has_finished_workflow']}
            expect(seen_all).to all be(true)
          end
        end

        context "with a finished workflow" do
          let(:workflow) do
            create(:workflow_with_subject_sets, finished_at: Time.zone.now)
          end

          before(:each) do
            workflow.subjects.map do |subject|
              create(:subject_workflow_status, workflow: workflow, subject: subject, retired_at: Time.zone.now)
            end
            get :index, request_params
          end

          it 'should return finished_workflow as true for each subject' do
            seen_all = json_response["subjects"].map{ |s| s['finished_workflow']}
            expect(seen_all).to all be(true)
          end

          it 'should return user_has_finished_workflow as true for each subject' do
            seen_all = json_response["subjects"].map{ |s| s['user_has_finished_workflow']}
            expect(seen_all).to all be(true)
          end

          it 'should return all subjects as retired' do
            retired = json_response["subjects"].map{ |s| s['retired']}
            expect(retired).to all( be true )
          end
        end

        context "without a workflow id" do
          before(:each) do
            get :index, request_params
          end

          let(:request_params) do
            { sort: 'queued' }
          end

          it 'should return 422' do
            expect(response.status).to eq(422)
          end
        end
      end

      context "with subject_set_ids" do
        let(:request_params) { { subject_set_id: subject_set.id.to_s } }

        before(:each) do
          get :index, request_params
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it 'should return a page of 2 objects' do
          get :index, request_params
          expect(json_response[api_resource_name].length).to eq(2)
        end

        it_behaves_like "an api response"
      end
    end
  end

  describe "#queued" do
    let(:api_resource_links) { [] }

    context "logged out user" do
      context "a queued request" do
        let!(:sms) { create_list(:set_member_subject, 2, subject_set: subject_set) }
        let(:request_params) { { workflow_id: workflow.id.to_s } }

        context "with queued subjects" do
          context "when firing the request before the test" do
            before(:each) do
              get :queued, request_params
            end

            it "should return 200" do
              expect(response.status).to eq(200)
            end

            it 'should return a page of 2 objects' do
              expect(json_response[api_resource_name].length).to eq(2)
            end

            it_behaves_like "an api response"

            context "with extraneous filtering params" do
              let!(:request_params) do
                { sort: 'queued', workflow_id: workflow.id.to_s, project_id: "1", collection_id: "1" }
              end

              it "should return 200" do
                expect(response.status).to eq(200)
              end

              it 'should return a page of 2 objects' do
                expect(json_response[api_resource_name].length).to eq(2)
              end
            end
          end

          context "with no data to select from" do
            before do
              allow_any_instance_of(Workflow)
              .to receive(:set_member_subjects)
              .and_return([])
            end

            it 'should return an error message', :aggregate_failures do
              get :queued, request_params
              expect(response.status).to eq(404)
              error_body = "No data available for selection"
              expect(response.body).to eq(json_error_message(error_body))
            end
          end

          context "with ordered subject selection" do
            it "should respect the order of the subjects from selector" do
              ordered_subject_ids = sms.map(&:subject_id).reverse.map(&:to_s)
              allow_any_instance_of(
                Subjects::Selector
              ).to receive(
                :get_subject_ids
              ).and_return(ordered_subject_ids)

              get :queued, request_params

              selected_subject_ids = created_instance_ids(api_resource_name)
              expect(selected_subject_ids).to eq(ordered_subject_ids)
            end

            it "should not try to order missing subject_ids" do
              allow_any_instance_of(
                Subjects::Selector
              ).to receive(
                :get_subject_ids
              ).and_return([])

              get :queued, request_params
              expect(json_response[api_resource_name].length).to eq(0)
            end
          end

          context "with deactivated subjects" do
            before do
              Subject
              .where(id: sms.map(&:subject_id))
              .update_all(activated_state: 1)
            end

            it "should return no subjects" do
              get :queued, request_params
              expect(json_response[api_resource_name].length).to eq(0)
            end
          end
        end
      end
    end

    context "logged in user" do
      before(:each) do
        default_request user_id: user.id, scopes: scopes
      end

      context "a queued request" do
        let!(:sms) { create_list(:set_member_subject, 2, subject_set: subject_set) }
        let(:request_params) { { workflow_id: workflow.id.to_s } }

        context "with subjects" do
          it "should return 200" do
            get :queued, request_params
            expect(response.status).to eq(200)
          end

          it 'should return a page of 2 objects' do
            get :queued, request_params
            expect(json_response[api_resource_name].length).to eq(2)
          end

          it 'should return already_seen as false' do
            get :queued, request_params
            already_seen = json_response["subjects"].map{ |s| s['already_seen']}
            expect(already_seen).to all( be false )
          end

          it 'should return finished_workflow as false' do
            get :queued, request_params
            seen_all = json_response["subjects"].map{ |s| s['finished_workflow']}
            expect(seen_all).to all( be false )
          end

          it 'should return retired as false' do
            get :queued, request_params
            retired = json_response["subjects"].map{ |s| s['retired']}
            expect(retired).to all( be false )
          end

          it_behaves_like "an api response" do
            before { get :queued, request_params }
          end
        end

        context "user has classified all subjects in the workflow" do
          let!(:seen_subjects) do
            create :classification, user: user, workflow: workflow, subjects: subjects
            create(:user_seen_subject,
                   user: user,
                   workflow: workflow,
                   subject_ids: subjects.map(&:id))
          end

          it 'should return already_seen true for each subject' do
            get :queued, request_params
            already_seen = json_response["subjects"].map{ |s| s['already_seen']}
            expect(already_seen).to all( be true )
          end

          it 'should return finished_workflow as false' do
            get :queued, request_params
            seen_all = json_response["subjects"].map{ |s| s['finished_workflow']}
            expect(seen_all).to all( be false )
          end

          it 'should return user_has_finished_workflow as true' do
            get :queued, request_params
            seen_all = json_response["subjects"].map{ |s| s['user_has_finished_workflow']}
            expect(seen_all).to all( be true )
          end
        end

        context "with a finished workflow" do
          let(:workflow) do
            create(:workflow_with_subject_sets, finished_at: Time.zone.now)
          end

          before(:each) do
            workflow.subjects.map do |subject|
              create(:subject_workflow_status, workflow: workflow, subject: subject, retired_at: Time.zone.now)
            end
            get :queued, request_params
          end

          it 'should return user finished_workflow as true for each subject' do
            seen_all = json_response["subjects"].map{ |s| s['finished_workflow']}
            expect(seen_all).to all be(true)
          end

          it 'should return all subjects as retired' do
            retired = json_response["subjects"].map{ |s| s['retired']}
            expect(retired).to all( be true )
          end
        end

        context "without a workflow id" do
          before(:each) do
            get :queued, request_params
          end

          let(:request_params) do
            { }
          end

          it 'should return 422' do
            expect(response.status).to eq(422)
          end
        end
      end
    end
  end

  describe '#grouped' do
    let(:workflow) do
      create(:workflow_with_subject_sets, configuration: { subject_group: { num_rows: 1, num_columns: 2 } })
    end
    let(:api_resource_links) { [] }
    let(:sms) { create_list(:set_member_subject, 2, subject_set: subject_set) }
    let(:request_params) { { workflow_id: workflow.id.to_s, num_columns: 2, num_rows: 1, http_cache: 'true' } }
    let(:flipper_feature) { Panoptes.flipper[:subject_group_selection].enable }

    before do
      ENV['SUBJECT_GROUP_WORKFLOW_ID_ALLOWLIST'] = workflow.id.to_s
      ENV['SUBJECT_GROUP_UPLOADER_ID'] = workflow.owner.id.to_s
      sms
      flipper_feature
      get :grouped, request_params
    end

    it 'returns 200' do
      expect(response.status).to eq(200)
    end

    it 'returns a page with only 1 resource' do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it_behaves_like 'an api response'

    context 'without num_rows and num_columns params' do
      let(:request_params) { { workflow_id: workflow.id.to_s } }

      it 'errors with 422' do
        expect(response.status).to eq(422)
      end

      it 'has a useful error message' do
        expect(response.body).to include('Num rows is required, Num columns is required')
      end
    end

    context 'with num_columns non integer param' do
      let(:request_params) { { workflow_id: workflow.id.to_s, num_columns: 'hmm', num_rows: 1 } }

      it 'errors with 422' do
        expect(response.status).to eq(422)
      end

      it 'has a useful error message' do
        expect(response.body).to include('Num columns is not a valid integer')
      end
    end

    context 'with num_rows array param' do
      let(:request_params) { { workflow_id: workflow.id.to_s, num_columns: 1, num_rows: [1] } }

      it 'errors with 422' do
        expect(response.status).to eq(422)
      end

      it 'has a useful error message' do
        expect(response.body).to include('found unpermitted parameter: num_rows')
      end
    end

    context 'with admin param' do
      let(:request_params) do
        { workflow_id: workflow.id.to_s, num_columns: 1, num_rows: 1, admin: true }
      end

      it 'responds with 200' do
        expect(response.status).to eq(200)
      end
    end

    context 'with a workflow that is not allow listed for this end point' do
      let(:request_params) { { workflow_id: (workflow.id - 1).to_s, num_columns: 1, num_rows: 1 } }

      it 'errors with 503' do
        expect(response.status).to eq(503)
      end

      it 'has a useful error message' do
        expect(response.body).to include('Feature has been temporarily disabled')
      end
    end

    context 'when the feature flag is disabled for this end point' do
      let(:flipper_feature) { Panoptes.flipper[:subject_group_selection].disable }

      it 'errors with 503' do
        expect(response.status).to eq(503)
      end

      it 'has a useful error message' do
        expect(response.body).to include('Feature has been temporarily disabled')
      end
    end
  end

  describe '#selection' do
    let(:workflow) { create(:workflow_with_subject_sets) }
    let(:api_resource_links) { [] }
    let(:sms) { create_list(:set_member_subject, 1, subject_set: subject_set) }
    let(:subject_ids) { sms.map(&:subject_id) }
    let(:request_params) do
      { workflow_id: workflow.id.to_s, ids: subject_ids.join(','), http_cache: 'true' }
    end
    let(:flipper_feature) { Panoptes.flipper[:subject_selection_by_ids].enable }

    before do
      subject_ids
      flipper_feature
      allow(SubjectSelectorSerializer).to receive(:page).and_call_original
      get :selection, request_params
    end

    it 'returns 200' do
      expect(response.status).to eq(200)
    end

    it 'returns a page with only 1 resource' do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it 'uses the SubjectSelectorSerializer class' do
      expect(SubjectSelectorSerializer).to have_received(:page)
    end

    it_behaves_like 'an api response'

    context 'without subject ids params' do
      let(:request_params) { { workflow_id: workflow.id.to_s } }

      it 'errors with 422' do
        expect(response.status).to eq(422)
      end

      it 'has a useful error message' do
        expect(response.body).to include('Ids is required')
      end
    end

    context 'when the feature flag is disabled for this end point' do
      let(:flipper_feature) { Panoptes.flipper[:subject_selection_by_ids].disable }

      it 'errors with 503' do
        expect(response.status).to eq(503)
      end

      it 'has a useful error message' do
        expect(response.body).to include('Feature has been temporarily disabled')
      end
    end
  end

  describe "#show" do
    let(:resource) { create(:subject) }

    it_behaves_like "is showable"

    describe "http caching" do
      let(:action) { :show }
      let(:private_resource) do
        project = create(:project, private: true) do |p|
          p.owner = user
        end
        create(:subject, project: project)
      end
      let(:private_resource_id) { private_resource.id }
      let(:public_resource_id) { resource.id }

      it_behaves_like "a showable unauthenticated http cacheable response"
      it_behaves_like "a showable authenticated http cacheable response"
    end
  end

  describe "#update" do
    let(:resource) do
      create(:subject, :with_mediums, num_media: 1, project: create(:project, owner: user))
    end
    let(:test_attr) { :metadata }
    let(:test_attr_value) do
      {
       "interesting_data" => "Tested Collection",
       "an_interesting_array" => ["1", "2", "asdf", "99.99"]
      }
    end
    let(:locations) { [ "image/jpeg" ] }
    let(:update_params) do
      {
       subjects: {
                  metadata: {
                             interesting_data: "Tested Collection",
                             an_interesting_array: ["1", "2", "asdf", "99.99"]
                            },
                  locations: locations
                 }
      }
    end

    it_behaves_like "is updatable"

    context "with an authorized user" do
      before do
        default_request user_id: authorized_user.id, scopes: scopes
      end

      describe "using external urls" do
        let(:external_locs) do
          [
            {"image/jpeg" => "http://example.com/1.jpg"},
            {"image/jpeg" => "http://example.com/2.jpg"}
          ]
        end
        let(:external_src_urls) do
          external_locs.map { |loc| loc.to_a.flatten[1] }
        end

        it 'should create externally linked media resources' do
          update_params[:subjects][:locations] = external_locs
          put :update, update_params.merge(id: resource.id)
          locations = Subject.find(created_instance_id("subjects")).locations
          aggregate_failures "external srcs" do
            expect(locations.map(&:external_link)).to all( be true )
            expect(locations.map(&:src)).to match_array(external_src_urls)
          end
        end
      end

      context "when the locations array is empty" do
        let(:locations) { [] }

        it "should not overwrite existing locations" do
          loc_ids = resource.locations.map(&:id)
          put :update, update_params.merge(id: resource.id)
          expect(loc_ids).to match_array(resource.reload.locations.map(&:id))
        end
      end
    end
  end

  describe "#create" do
    let(:test_attr) { :metadata }
    let(:test_attr_value) do
      { "cool_factor" => "11" }
    end

    let(:create_params) do
      {
       subjects: {
                  metadata: { cool_factor: "11" },
                  locations: ["image/jpeg", "image/jpeg", "image/png"],
                  links: {
                          project: project.id
                         }
                 }
      }
    end

    context "Uploading is disabled" do
      before { Panoptes.flipper[:subject_uploading].disable }

      it "raises an error when uploading is disabled" do
        default_request user_id: authorized_user.id, scopes: scopes
        post :create, create_params
        expect(response.status).to be(503)
      end
    end

    it "should incremement the user's subjects_count cache and touch the user" do
      expect_any_instance_of(User).to receive(:increment_subjects_count_cache)
      default_request user_id: authorized_user.id, scopes: scopes
      post :create, create_params
    end

    it "should return locations in the order they were submitted" do
      default_request user_id: authorized_user.id, scopes: scopes
      post :create, create_params
      locations = json_response[api_resource_name][0]["locations"].flat_map(&:keys)
      expect(locations).to eq(["image/jpeg", "image/jpeg", "image/png"])
    end

    it "should replace non-standard mimetypes" do
      create_params[:subjects][:locations] = ["audio/mp3", "audio/x-wav"]
      default_request user_id: authorized_user.id, scopes: scopes
      post :create, create_params
      locations = json_response[api_resource_name][0]["locations"].flat_map(&:keys)
      expect(locations).to eq(["audio/mpeg", "audio/mpeg"])
    end

    it 'should create externally linked media resources' do
      default_request user_id: authorized_user.id, scopes: scopes
      external_locs = [{"image/jpeg" => "http://example.com/1.jpg"}, {"image/jpeg" => "http://example.com/2.jpg"}]
      external_src_urls = external_locs.map { |loc| loc.to_a.flatten[1] }
      create_params[:subjects][:locations] = external_locs
      post :create, create_params
      locations = Subject.find(created_instance_id("subjects")).locations
      aggregate_failures "external srcs" do
        expect(locations.map(&:external_link)).to all( be true )
        expect(locations.map(&:src)).to match_array(external_src_urls)
      end
    end

    context "when the user is not-the owner of the project" do
      let(:unauthorised_user) { create(:user) }

      let(:upload_subjects) do
        default_request scopes: scopes, user_id: unauthorised_user.id
        post :create, create_params
      end

      it 'should return unprocessable entity' do
        upload_subjects
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should scrub any schema sql from the error message' do
        upload_subjects
        expect(response.body).to eq(json_error_message("Couldn't find linked project for current user"))
      end

      context "when the user is an admin" do
        before(:each) do
          allow_any_instance_of(ApiUser).to receive(:is_admin?).and_return(true)
        end

        it 'should return the created status' do
          upload_subjects
          expect(response).to have_http_status(:created)
        end

        context "when uploading restricted content_types" do
          it 'should return the created status' do
            create_params.deep_merge!({ subjects: { locations: [ "video/mp4" ] } })
            upload_subjects
            expect(response).to have_http_status(:created)
          end
        end
      end
    end

    context "when the user has exceeded the allowed number of subjects" do
      let(:upload_subjects) do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
      end

      before(:each) do
        allow_any_instance_of(User).to receive(:uploaded_subjects_count).and_return(101)
      end

      it 'should return 403' do
        upload_subjects
        expect(response).to have_http_status(:forbidden)
      end

      it 'should have an error message' do
        upload_subjects
        msg = json_response["errors"][0]["message"]
        expect(msg).to match(/User has uploaded [0-9]+ subjects of [0-9]+ maximum/)
      end

      context "when the user is an admin" do
        it 'should return the created status' do
          allow_any_instance_of(ApiUser).to receive(:is_admin?).and_return(true)
          upload_subjects
          expect(response).to have_http_status(:created)
        end
      end

      context "when the user is whitelisted to upload" do
        it 'should return the created status' do
          allow_any_instance_of(User).to receive(:upload_whitelist).and_return(true)
          upload_subjects
          expect(response).to have_http_status(:created)
        end
      end
    end

    context "when the project is owned by the user" do
      it_behaves_like "is creatable"
    end

    context "when the project is owned by a user_group the user may edit" do
      let(:membership) { create(:membership, state: 0, roles: ["project_editor"]) }
      let(:project) { create(:project, owner: membership.user_group) }
      let(:authorized_user) { membership.user }

      it_behaves_like "is creatable"
    end
  end

  describe "#destroy" do
    let(:resource) { create(:subject, project: create(:project, owner: user)) }
    let(:instances_to_disable) { [resource] }

    it_behaves_like "is deactivatable"

    it "should background a job to cleanup orphan subjects" do
      stub_token(scopes: scopes, user_id: authorized_user.id)
      set_preconditions
      expect(SubjectRemovalWorker).to receive(:perform_async).with(resource.id)
      delete :destroy, id: resource.id
    end

    it "should handle redis timeout error" do
      stub_token(scopes: scopes, user_id: authorized_user.id)
      set_preconditions
      expect(SubjectRemovalWorker).to receive(:perform_async).and_raise(Timeout::Error)
      delete :destroy, id: resource.id
    end
  end
end
