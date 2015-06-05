require 'spec_helper'

describe Api::V1::UsersController, type: :controller do
  let!(:users) {
    create_list(:user_with_avatar, 22)
  }

  let(:scopes) { %w(public user) }

  let(:api_resource_name) { "users" }
  let(:api_resource_attributes) do
    [ "id", "display_name", "credited_name", "email",
      "created_at", "updated_at", "type",
      "global_email_communication", "project_email_communication",
      "beta_email_communication" ]
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

  let(:response_fb_token) do
    json_response[api_resource_name][0]["firebase_auth_token"]
  end

  describe "#index" do
    context "with an authenticated user" do
      before(:each) do
        default_request(scopes: scopes, user_id: users.first.id)
        get :index
      end

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should have twenty items by default" do
        expect(json_response[api_resource_name].length).to eq(20)
      end

      it_behaves_like "an api response"
      it_behaves_like 'an indexable etag response'
    end

    context "an unauthenticated request" do
      before(:each) do
        unauthenticated_request
        get :index
      end

      it 'should have an empty string email address' do
        expect(json_response[api_resource_name]).to all( include("email" => "") )
      end

      it 'should have an empty string credited name' do
        expect(json_response[api_resource_name]).to all( include("credited_name" => "") )
      end

      it 'should have an empty string global email communication' do
        expect(json_response[api_resource_name]).to all( include("global_email_communication" => "") )
      end

      it 'should have an empty string project email communication' do
        expect(json_response[api_resource_name]).to all( include("project_email_communication" => "") )
      end

      it 'should have an empty string beta email communication' do
        expect(json_response[api_resource_name]).to all( include("beta_email_communication" => "") )
      end

      it "should have an empty string for the uploaded_subjects_count" do
        expect(json_response[api_resource_name]).to all( include("uploaded_subjects_count" => 0) )
      end

      it "should have an empty string for the max_subjects" do
        expect(json_response[api_resource_name]).to all( include("max_subjects" => 0) )
      end
    end

    describe "params" do
      let(:user) { users.sample(1).first }

      before(:each) do
        get :index, index_options
      end

      describe "filter by display_name" do
        let(:index_options) { { slug: user.identity_group.slug } }

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          expect(json_response[api_resource_name][0]['display_name']).to eq(user.display_name)
        end
      end

      describe "filter by display_name" do
        let(:index_options) { { display_name: user.display_name } }

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          expect(json_response[api_resource_name][0]['display_name']).to eq(user.display_name)
        end
      end

      describe "filter by case insensitive display_name" do
        let(:index_options) { { display_name: user.display_name.upcase } }

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          expect(json_response[api_resource_name][0]['display_name']).to eq(user.display_name)
        end
      end

      describe "include avatars" do
        let(:index_options) { { include: 'avatar' } }

        it 'should have the included resources' do
          expect(json_response["linked"]["avatars"].map{ |r| r['id'] })
            .to match_array(users.take(20).map(&:avatar).map(&:id).map(&:to_s))
        end
      end
    end

    describe "overridden serialiser instance assocation links" do

      before(:each) do
        user = users.first
        create(:classification, user: user)
        get :index, { display_name: user.display_name }
      end

      it "should respond with 1 item" do
        expect(json_response[api_resource_name].length).to eq(1)
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
        get :show, id: users.first.id
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
        expect(projects_link).to eq("/projects?owner={users.slug}")
      end

      it 'should include a customized url for collections' do
        collections_link = json_response['links']['users.collections']['href']
        expect(collections_link).to eq("/collections?owner={users.slug}")
      end

      it_behaves_like "an api response"
    end

    describe "firebase JWT token" do
      let(:show_id) { users.first.id }

      before(:each) do
        default_request(scopes: scopes, user_id: requesting_user_id)
        allow_any_instance_of(UserSerializer)
          .to receive(:show_firebase_token?).and_return(false)
        get :show, id: show_id
      end

      context "when showing the a different user to the requesting user" do
        let(:requesting_user_id) { users.last.id }

        it "should not have a firebase auth token for the user" do
          expect(response_fb_token).to be_nil
        end
      end

      context "when showing the requesting user" do
        let(:requesting_user_id) { show_id }

        it "should not have a firebase auth token for the user" do
          expect(response_fb_token).to be_nil
        end
      end
    end
  end

  describe "#me" do
    let(:jwt_token) { "completely_fake_jwt_token" }
    let(:user) { users.first }

    before(:each) do
      allow_any_instance_of(Firebase::FirebaseTokenGenerator)
        .to receive(:create_token).and_return(jwt_token)
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

    it "should have a firebase auth token for the user" do
      expect(response_fb_token).to eq(jwt_token)
    end

    it "should have the user's uploaded_subjects_count" do
      uploaded_subjects = created_instance(api_resource_name)["uploaded_subjects_count"]
      expect(uploaded_subjects).to eq(user.uploaded_subjects_count)
    end

    it "should have the user's max_subjects" do
      max_subjects = created_instance(api_resource_name)["max_subjects"]
      expect(max_subjects).to eq(Panoptes.max_subjects)
    end

    it "should have a the global email communication for the user" do
      expect(created_instance(api_resource_name)["global_email_communication"]).to eq(true)
    end

    it "should have a the project email communication for the user" do
      expect(created_instance(api_resource_name)["project_email_communication"]).to eq(true)
    end

    it "should have a the beta email communication for the user" do
      expect(created_instance(api_resource_name)["beta_email_communication"]).to eq(true)
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
      put :update, params
    end

    context "when changing email" do
      let(:put_operations) { {users: {email: "test@example.com"}} }

      after(:each) do
        update_request
      end

      context 'when email preferences are true' do
        it 'should subscribe the new email' do
          expect(SubscribeWorker).to receive(:perform_async).with("test@example.com",
                                                                  user.display_name)
        end

        it 'should remove the old email' do
          expect(UnsubscribeWorker).to receive(:perform_async).with(user.email)
        end
      end

      context 'when email prefences are false' do
        let(:user) { create(:user, global_email_communication: false) }
        it 'should subscribe the new email' do
          expect(SubscribeWorker).to_not receive(:perform_async)
        end

        it 'should not call unsubscribe' do
          expect(UnsubscribeWorker).to_not receive(:perform_async)
        end
      end
    end

    context "when changing global_email_communication" do
      after(:each) do
        update_request
      end

      context "from false to true" do
        let(:user) { create(:user, global_email_communication: false) }
        let(:put_operations) { {users: {global_email_communication: true}} }

        it 'should queue a subscribe worker' do
          expect(SubscribeWorker).to receive(:perform_async).with(user.email,
                                                                  user.display_name)
        end
      end

      context "from true to false" do
        let(:user) { create(:user, global_email_communication: true) }
        let(:put_operations) { {users: {display_name: "TEST", global_email_communication: false}} }
        it 'should queue an unsubscribe worker' do
          expect(UnsubscribeWorker).to receive(:perform_async).with(user.email)
        end
      end

      context "from true to true" do
        let(:user) { create(:user, global_email_communication: true) }
        let(:put_operations) { {users: {global_email_communication: true}} }
        it 'should not queue a subscribe worker' do
          expect(SubscribeWorker).to_not receive(:perform_async)
        end

        it 'should not queue a unsubscribe worker' do
          expect(UnsubscribeWorker).to_not receive(:perform_async)
        end
      end

      context "from false to false" do
        let(:user) { create(:user, global_email_communication: false) }
        let(:put_operations) { {users: {global_email_communication: false}} }
        it 'should not queue a subscribe worker' do
          expect(SubscribeWorker).to_not receive(:perform_async)
        end

        it 'should not queue a unsubscribe worker' do
          expect(UnsubscribeWorker).to_not receive(:perform_async)
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
      let(:new_display_name) { "Mr_Creosote" }
      let(:new_gec) { false }
      let(:new_pec) { false }
      let(:new_bec) { false }
      let(:put_operations) do
        { users: { display_name: new_display_name,
                   global_email_communication: new_gec,
                   project_email_communication: new_pec,
                   beta_email_communication: new_bec } }
      end

      it "should return 200 status" do
        expect(response).to have_http_status(:ok)
      end

      it "should have updated the display_name attribute" do
        expect(user.reload.display_name).to eq(new_display_name)
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
        prev_display_name = user.display_name
        expect(user.reload.display_name).to eq(prev_display_name)
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
        error_message = json_error_message("found unpermitted parameter: project_id")
        expect(response.body).to eq(error_message)
      end

      it "should not updated the resource attribute" do
        expect(user.reload.project_id).to eq(prev_project_id)
      end
    end
  end

  describe "#destroy" do
    let(:user) { users.first}
    let(:user_id) { user.id }
    let(:access_token) { create(:access_token) }

    before(:each) do
      default_request(scopes: scopes, user_id: users.first.id)
      allow(Doorkeeper).to receive(:authenticate).and_return(access_token)
    end

    it "should call the UserInfoScrubber with the user" do
      expect(UserInfoScrubber).to receive(:scrub_personal_info!).with(user)
      delete :destroy, id: user_id
    end

    it "should revoke the request doorkeeper token" do
      delete :destroy, id: user_id
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
