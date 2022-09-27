require 'spec_helper'

describe Api::V1::UsersController, type: :controller do
  let!(:users) {
    create_list(:user, 2, :avatar, :languages)
  }

  let(:scopes) { %w(public user) }

  let(:api_resource_name) { "users" }
  let(:api_resource_attributes) do
    [ "id", "display_name", "created_at", "updated_at", "type"]
  end

  let(:api_resource_links) do
    [ "users.projects",
      "users.avatar",
      "users.collections",
      "users.classifications",
      "users.project_preferences",
      "users.collection_preferences",
      "users.recents" ]
  end
  let(:deactivated_resource) { create(:user, activated_state: :inactive) }

  describe "#index" do
    context "with an authenticated user" do
      before(:each) do
        default_request(scopes: scopes, user_id: users.first.id)
        get :index
      end

      it_behaves_like "it only lists active resources"

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should have twenty items by default" do
        expect(json_response[api_resource_name].length).to eq(2)
      end

      it_behaves_like "an api response"
      it_behaves_like 'an indexable etag response'
    end

    describe "params" do
      let(:user) { users.sample(1).first }
      let(:resource) { user }

      before(:each) do
        default_request(scopes: scopes, user_id: user.id)
        get :index, params: index_options
      end

      it_behaves_like "filter by display_name"

      describe "filter by login" do
        let(:index_options) { { login: user.login } }

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          expect(json_response[api_resource_name][0]['display_name']).to eq(user.display_name)
        end
      end

      describe "filter by case insensitive login" do
        let(:index_options) { { login: user.login.upcase } }

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          expect(json_response[api_resource_name][0]['display_name']).to eq(user.display_name)
        end
      end

      describe "filter by email (non-admin)" do
        let(:index_options) { { email: user.email} }

        it "should respond with 2 items" do
          expect(json_response[api_resource_name].length).to eq(2)
        end
      end

      describe "filter by case insensitive email (non-admin)" do
        let(:index_options) { { email: user.email.upcase } }

        it "should respond with 2 items" do
          expect(json_response[api_resource_name].length).to eq(2)
        end
      end

      context "as an admin user" do
        let(:user) { create(:user, admin: true) }
        let(:email) { user.email }
        let(:index_options) do
          { email: email, admin: true}
        end

        describe "filter by email" do
          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            expect(json_response[api_resource_name][0]['display_name']).to eq(user.display_name)
          end

          context "with filtering emails on multiple emails" do
            let(:another_user) { create(:user) }
            let(:emails_filter) do
              [ email, another_user.email ].map(&:upcase).join(',')
            end
            let(:index_options) do
              { email: emails_filter, admin: true, page_size: 1 }
            end

            it "should respond include the filter in the next href" do
              next_href = json_response.dig("meta", "users", "next_href")
              expect(next_href).to include("email=#{emails_filter}")
            end
          end
        end

        describe "filter by case insensitive email" do
          let(:email) { user.email.upcase }

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            expect(json_response[api_resource_name][0]['display_name']).to eq(user.display_name)
          end
        end
      end

      describe "include avatars" do
        let(:index_options) { { include: 'avatar' } }

        it 'should have the included resources' do
          expect(json_response["linked"]["avatars"].map{ |r| r['id'] })
            .to match_array(users.map(&:avatar).map(&:id).map(&:to_s))
        end
      end

      describe "search" do
        let(:index_options) { { search: user.login } }

        it "should respond with the correct user", :aggregate_failures do
          expect(json_response[api_resource_name].length).to eq(1)
          expect(json_response[api_resource_name][0]['login']).to eq(user.login)
        end

        context "fuzzy matching against the login field" do
          let(:similar_user){ create :user, login: 'bill_murray', display_name: 'Bill Murray' }
          let(:index_options) { { search: similar_user.display_name } }

          it 'should respond with the user' do
            result_id = created_instance_id(api_resource_name)
            expect(result_id).to eq(similar_user.id.to_s)
          end
        end

        context "non-matching display_name or login" do
          let(:index_options) { { search: "bill murray" } }

          it "should not return any data" do
            expect(json_response[api_resource_name].length).to eq(0)
          end
        end

        context "with a limited page size" do
          let(:index_options) { { search: user.login, page_size: 1 } }

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            result = json_response[api_resource_name][0]['login']
            expect(result).to eq(user.login)
          end
        end

        context "with partial strings" do
          let(:index_options) { { search: partial } }

          context "partials that don't hit any trigrams" do
            let(:partial) { user.login[0..1] }

            it "should not find any users" do
              expect(json_response[api_resource_name].length).to eq(0)
            end
          end

          context "partials that match the trigrams" do
            let(:partial) { user.login[0..2] }

            it "should find both users" do
              expect(json_response[api_resource_name].length).to eq(2)
            end
          end
        end

        context "with hard to find tsvector" do
          let(:hard_name) { "S_Powell" }
          let(:hard_user) do
            create(:user, login: hard_name)
          end
          let(:index_options) { { search: hard_user.login } }

          it "should respond with the hard user" do
            result_id = created_instance_id(api_resource_name)
            expect(result_id).to eq(hard_user.id.to_s)
          end
        end

        context 'with invalid search characters' do
          let(:index_options){ { search: '@some&@!_(   )user' } }

          it 'should strip the invalid characters' do
            expect_any_instance_of(User.const_get('ActiveRecord_Relation'))
              .to receive(:full_search_login).with('some_user').and_call_original
            get :index, params: index_options
          end
        end

        context 'with a short search string' do
          let(:index_options){ { search: 'me' } }

          it 'should abort the query', :aggregate_failures do
            expect_any_instance_of(User.const_get('ActiveRecord_Relation'))
              .to_not receive(:full_search_login)
            expect(User).to receive(:none).and_call_original
            get :index, params: index_options
          end

          context 'when a user has that login' do
            let!(:short_user){ create :user, login: 'me' }
            let(:index_options){ { search: short_user.login } }

            it 'should find the user' do
              result_id = created_instance_id api_resource_name
              expect(result_id).to eq(short_user.id.to_s)
            end
          end
        end
      end
    end

    describe "overridden serialiser instance assocation links" do
      let(:user){ users.sample }

      before(:each) do
        create(:classification, user: user)
        get :index, params: { login: user.login }
      end
      it "should respond with the no model links" do
        expect(json_response[api_resource_name][0]['links']).to eq({})
      end
    end
  end

  describe "#show" do

    context "when showing the requesting user" do

      before(:each) do
        default_request(scopes: scopes, user_id: users.first.id)
        get :show, params: { id: users.first.id }
      end

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should have a single user" do
        expect(json_response["users"].length).to eq(1)
      end

      it "should have the user's email" do
        expect(created_instance(api_resource_name)['email']).to_not be_nil
      end

      it 'should include a customized url for projects' do
        projects_link = json_response['links']['users.projects']['href']
        expect(projects_link).to eq("/projects?owner={users.login}")
      end

      it 'should include a customized url for collections' do
        collections_link = json_response['links']['users.collections']['href']
        expect(collections_link).to eq("/collections?owner={users.login}")
      end

      it_behaves_like "an api response"
    end

    describe "admin" do
      let(:show_id) { users.first.id }
      let(:admin_response) { created_instance(api_resource_name)["admin"] }

      before(:each) do
        allow_any_instance_of(User).to receive(:admin).and_return(true)
        default_request(scopes: scopes, user_id: requesting_user_id)
        get :show, params: { id: show_id }
      end

      context "when showing the a different user to the requesting user" do
        let(:requesting_user_id) { users.last.id }

        it "should not have the admin field" do
          expect(json_response[api_resource_name][0]).to_not include("admin")
        end
      end

      context "when showing the requesting user" do
        let(:requesting_user_id) { show_id }

        it "should have the admin flag set" do
          expect(admin_response).to eq(true)
        end
      end
    end
  end

  describe "#me" do
    let(:user) { users.first }
    let(:user_response) { created_instance(api_resource_name) }

    before(:each) do
      user.save
      default_request(scopes: scopes, user_id: user.id)
      get :me
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should return the Last-Modified header" do
      expected_date = user.updated_at.httpdate
      expect(response.headers["Last-Modified"]).to eq(expected_date)
    end

    it "should have a single user" do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it "should have the user's uploaded_subjects_count" do
      uploaded_subjects = user_response["uploaded_subjects_count"]
      expect(uploaded_subjects).to eq(user.uploaded_subjects_count)
    end

    it "should have the user's subject_limit" do
      subject_limit = user_response["subject_limit"]
      expect(subject_limit).to eq(Panoptes.max_subjects)
    end

    it "should have the languages for the user" do
      expect(user_response["languages"]).to eq(["en", "es", "fr-ca"])
    end

    it "should have the global email communication for the user" do
      expect(user_response["global_email_communication"]).to eq(true)
    end

    it "should have the project email communication for the user" do
      expect(user_response["project_email_communication"]).to eq(true)
    end

    it "should have the beta email communication for the user" do
      expect(user_response["beta_email_communication"]).to eq(true)
    end

    it "should have the nasa email communication for the user" do
      expect(user_response["nasa_email_communication"]).to eq(false)
    end

    it "should have the zooniverse_id for the user" do
      result = user_response["zooniverse_id"]
      expect(result).to eq(user.zooniverse_id)
    end

    it "should have the upload_whitelist for the user" do
      result = user_response["upload_whitelist"]
      expect(result).to eq(user.upload_whitelist)
    end

    it_behaves_like "an api response"
  end

  describe "#update" do
    let(:user) { users.first }
    let(:user_id) { user.id }

    def update_request
      default_request(scopes: scopes, user_id: user.id)
      params = put_operations || Hash.new
      params[:id] = user_id
      put :update, params: params
    end

    shared_examples 'admin only attribute' do |attribute, value|
      let(:attr_val_update) { { "#{attribute}" => value } }

      before(:each) do
        update_request
      end

      context "when user is an admin" do
        let(:put_operations) { {admin: true, users: attr_val_update } }
        let(:user) { create(:user, admin: true) }

        it 'should update users attribute' do
          val = user.reload.send(attribute)
          expect(val).to eq(value)
        end

        context "admin updating another user" do
          let(:user_id) { users.last.id }

          it "should return 200 status" do
            expect(response).to have_http_status(:ok)
          end

          it "should have updated the other user's subject_limit" do
            val = users.last.reload.send(attribute)
            expect(val).to eq(value)
          end
        end
      end

      context "when user is not an admin" do
        let(:put_operations) { { users: attr_val_update } }

        it 'should fail with a 422 error' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "subject_limit" do

      it_behaves_like "admin only attribute", :subject_limit, 10
    end

    describe "upload_whitelist" do

      it_behaves_like "admin only attribute", :upload_whitelist, true
    end

    describe "banned" do

      it_behaves_like "admin only attribute", :banned, true
    end

    describe "valid_email" do

      it_behaves_like "admin only attribute", :valid_email, true
    end

    context "when changing email" do
      let(:put_operations) { {users: {email: "test@example.com"}} }

      after(:each) do
        update_request
      end

      it "sends an email to the new address if user is valid" do
        expect(UserInfoChangedMailerWorker).to receive(:perform_async).with(user.id, "email")
      end

      describe "with an email that already exists" do
        let(:put_operations) { {users: {email: User.where.not(id: user.id).first.email}} }
        it "doesn't send an email to the new address if user is not valid" do
          expect(UserInfoChangedMailerWorker).to_not receive(:perform_async).with(user.id, "email")
        end
      end
    end

    context "when updating a non-existant user" do
      before(:each) { update_request }
      let!(:user_id) { User.last.id + 1 }
      let(:put_operations) { nil }

      it "should return a 404 status" do
        expect(response.status).to eq(404)
      end

      it "should return a specific error message in the response body" do
        error_message = json_error_message("Could not find user with id='#{user_id}'")
        expect(response.body).to eq(error_message)
      end
    end

    context "with a valid replace put operation" do
      before(:each) { update_request }
      let(:new_login) { "Mr_Creosote" }
      let(:new_gec) { false }
      let(:new_pec) { false }
      let(:new_bec) { false }
      let(:new_nec) { true }
      let(:new_ux_testing) { false }
      let(:new_intervention_notifications) { false }
      let(:put_operations) do
        {
          users: {
            login: new_login,
            global_email_communication: new_gec,
            project_email_communication: new_pec,
            beta_email_communication: new_bec,
            nasa_email_communication: new_nec,
            ux_testing_email_communication: new_ux_testing,
            intervention_notifications: new_intervention_notifications
          }
        }
      end

      it "should return 200 status" do
        expect(response).to have_http_status(:ok)
      end

      it "should have updated the login attribute" do
        expect(user.reload.login).to eq(new_login)
      end

      it "should have updated the global email communication attribute" do
        expect(user.reload.global_email_communication).to eq(new_gec)
      end

      it "should have updated the project email communication attribute" do
        expect(user.reload.project_email_communication).to eq(new_pec)
      end

      it "should have updated the beta email communication attribute" do
        expect(user.reload.beta_email_communication).to eq(new_bec)
      end

      it "should have updated the nasa email communication attribute" do
        expect(user.reload.nasa_email_communication).to eq(new_nec)
      end

      it "should have updated the ux testing email comms attribute" do
        expect(user.reload.ux_testing_email_communication).to eq(new_bec)
      end

      it "should have updated the intervention notifications attribute" do
        expect(user.reload.intervention_notifications).to eq(new_bec)
      end

      it "should have a single group" do
        expect(json_response[api_resource_name].length).to eq(1)
      end

      it_behaves_like "an api response"
    end

    context "with a an invalid put operation" do
      before(:each) { update_request }
      let(:put_operations) { {} }

      it "should return an error status" do
        expect(response.status).to eq(422)
      end

      it "should return a specific error message in the response body" do
        error_message = json_error_message("param is missing or the value is empty: users")
        expect(response.body).to eq(error_message)
      end

      it "should not updated the resource attribute" do
        prev_login = user.login
        expect(user.reload.login).to eq(prev_login)
      end
    end

    context "when attempting to update the project_id" do
      let!(:prev_project_id) { user.project_id }
      let(:put_operations) { { users: { project_id: 2 } } }
      before(:each) { update_request }

      it "should return an error status" do
        expect(response.status).to eq(422)
      end

      it "should return a specific error message in the response body" do
        error_message = json_error_message("found unpermitted parameter: :project_id")
        expect(response.body).to eq(error_message)
      end

      it "should not updated the resource attribute" do
        expect(user.reload.project_id).to eq(prev_project_id)
      end
    end

    context "when unsubscribing from project emails" do
      let(:put_operations) do
        { users: { project_email_communication: false } }
      end
      let(:user_project_preferences) do
        create(:user_project_preference, user: user)
      end

      it "should not modify any of the user project emails prefs" do
        user_project_preferences
        expect {
          update_request
        }.not_to change {
          user_project_preferences.reload.email_communication
        }
      end
    end
  end

  describe "#destroy" do
    let(:user) { users.first}
    let(:user_id) { user.id }
    let(:access_token) { create(:access_token, resource_owner_id: user_id) }

    before(:each) do
      default_request(scopes: scopes, user_id: users.first.id)
      allow(Doorkeeper).to receive(:authenticate).and_return(access_token)
    end

    it "should call the UserInfoScrubber with the user" do
      expect(UserInfoScrubber).to receive(:scrub_personal_info!).with(user)
      delete :destroy, params: { id: user_id }
    end

    it "should revoke the request doorkeeper token" do
      delete :destroy, params: { id: user_id }
      expect(access_token.reload.revoked?).to eq(true)
    end

    let(:authorized_user) { user }
    let(:resource) { user }
    let(:instances_to_disable) do
      [resource] |
        resource.projects |
        resource.memberships |
        resource.collections
    end

    it_behaves_like "is deactivatable"
  end

  describe "#recents" do
    let(:authorized_user) { users.first }
    let(:resource) { authorized_user }
    let(:resource_key) { :user }
    let(:resource_key_id) { :user_id }

    it_behaves_like "has recents"
  end
end
