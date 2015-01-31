require 'spec_helper'

describe Api::V1::UsersController, type: :controller do
  let!(:users) {
    create_list(:user, 22)
  }

  let(:scopes) { %w(public user) }

  let(:api_resource_name) { "users" }
  let(:api_resource_attributes) do
    [ "id", "login", "display_name", "credited_name", "email", "created_at", "updated_at", "type" ]
  end
  let(:api_resource_links) do
    [ "users.projects",
      "users.collections",
      "users.classifications",
      "users.project_preferences",
      "users.collection_preferences" ]
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
    end

    context "an unauthenticated request" do
      before(:each) do
        unauthenticated_request
        get :index
      end

      it 'should have a nil email address' do
        expect(json_response[api_resource_name]).to all( include("email" => nil) )
      end

      it 'should have a nil credited name' do
        expect(json_response[api_resource_name]).to all( include("credited_name" => nil) )
      end
    end

    describe "filter params" do
      let(:user) { users.sample(1).first }

      before(:each) do
        get :index, index_options
      end

      describe "filter by login" do
        let(:index_options) { { login: user.login } }

        it "should respond with 1 item" do
          expect(json_response[api_resource_name].length).to eq(1)
        end

        it "should respond with the correct item" do
          expect(json_response[api_resource_name][0]['login']).to eq(user.login)
        end
      end
    end

    describe "overridden serialiser instance assocation links" do

      before(:each) do
        user = users.first
        create(:classification, user: user)
        get :index, { login: user.login }
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
      expect(json_response['users'][0]['email']).to_not be_nil
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

  describe "#me" do
    before(:each) do
      default_request(scopes: scopes, user_id: users.first.id)
      get :me
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should have a single user" do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it_behaves_like "an api response"
  end

  describe "#update" do
    let(:user) { users.first }
    let(:user_id) { user.id }

    before(:each) do
      default_request(scopes: scopes, user_id: users.first.id)
      params = put_operations || Hash.new
      params[:id] = user_id
      put :update, params
    end

    context "when updating a non-existant user" do
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
      let(:new_display_name) { "Mr Creosote" }
      let(:put_operations) do
        { users: { display_name: new_display_name } }
      end

      it "should return 200 status" do
        expect(response.status).to eq(200)
      end

      it "should have updated the attribute" do
        expect(user.reload.display_name).to eq(new_display_name)
      end

      it "should have a single group" do
        expect(json_response[api_resource_name].length).to eq(1)
      end

      it_behaves_like "an api response"
    end

    context "with a an invalid put operation" do
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

    context "with and put operation that sets a required attribute to nil" do
      let(:put_operations) { {users: { login: "" }} }

      it "should return a bad request status" do
        expect(response.status).to eq(422)
      end

      it "should return a specific error message in the response body" do
        error_message = json_error_message("found unpermitted parameters: login")
        expect(response.body).to eq(error_message)
      end

      it "should not updated the resource attribute" do
        prev_login = user.login
        expect(user.reload.login).to eq(prev_login)
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
end
