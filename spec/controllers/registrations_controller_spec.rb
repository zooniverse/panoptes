require 'spec_helper'

describe RegistrationsController, type: :controller do

  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  let(:user_attributes) do
    attributes_for(:user, **extra_attributes)
      .slice(:email, :password, :password_confirmation, :login, :name,
             :global_email_communication, :project_email_communication)
  end

  context "as json" do

    describe "#create" do
      before(:each) do
        request.env["HTTP_ACCEPT"] = "application/json"
      end

      context "with valid user attributes" do
        let(:login) { "mcMMO-Dev" }
        let(:extra_attributes) { {login: login, display_name: nil} }

        it "should return 201" do
          post :create, user: user_attributes
          expect(response.status).to eq(201)
        end

        it "should increase the count of users" do
          expect{ post :create, user: user_attributes }.to change{ User.count }.from(0).to(1)
        end

        it "should persist the user account" do
          post :create, user: user_attributes
          expect(User.find(created_instance_id("users"))).to_not be_nil
        end

        it "should sign the user in" do
          expect(subject).to receive(:sign_in)
          post :create, user: user_attributes
        end

        it "should clear the password attributes" do
          expect(subject).to receive(:clean_up_passwords)
          post :create, user: user_attributes
        end

        it "should set the display name to be the exact replica of the login field" do
          post :create, user: user_attributes
          expect(User.find(created_instance_id("users")).display_name).to eq(login)
        end
      end

      context "with caps and spaces in the login name" do
        let(:extra_attributes) { { login: "Test User Login" } }

        it "should convert the owner_name#name field correctly" do
          post :create, user: user_attributes
          owner_uniq_name = User.find(created_instance_id("users")).owner_uniq_name
          expect(owner_uniq_name).to eq("test_user_login")
        end
      end

      context "with invalid user attributes" do
        let(:extra_attributes) { { login: nil } }

        it "should return 422" do
          post :create, user: user_attributes
          expect(response.status).to eq(422)
        end

        it "should not increase the count of users" do
          expect{ post :create, user: user_attributes }.not_to change{ User.count }
        end

        it "should not persist the user account" do
          post :create, user: user_attributes
          expect(User.where(login: user_attributes[:login])).to_not exist
        end

        it "should provide an error message in the response body" do
          post :create, user: user_attributes
          error_body = { "owner_name.name" => ["can't be blank"],"login" => ["can't be blank"] }
          expect(response.body).to eq(json_error_message(error_body))
        end
      end
    end
  end
end
