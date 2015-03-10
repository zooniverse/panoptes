require 'spec_helper'

describe RegistrationsController, type: :controller do
  let(:user_attributes) do
    attributes_for(:user, **extra_attributes).slice(*user_params)
  end

  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  context "as json" do
    let(:user_params) do
      [ :email, :password, :password_confirmation, :display_name,
        :global_email_communication, :project_email_communication ]
    end

    before(:each) do
      request.env["HTTP_ACCEPT"] = "application/json"
    end

    describe "#create" do

      context "with valid user attributes" do
        let(:login) { "mcMMO-Dev" }
        let(:extra_attributes) { { display_name: login} }

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

        it "should create a new ZooniverseUser" do
          post :create, user: user_attributes
          expect(ZooniverseUser.where(login: login).first).to_not be_nil
        end

        context "when the user already exists in zooniverse_home" do
          let!(:existing_zoo_user) { create(:zooniverse_user, login: login) }

          it "should not create the panotpes user" do
            expect { post :create, user: user_attributes }.not_to change{ User.count }
          end

          it "should return 422" do
            post :create, user: user_attributes
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "should not sign the user in" do
            expect(subject).to_not receive(:sign_in)
            post :create, user: user_attributes
          end
        end
      end

      context "with caps and spaces in the display name" do
        let(:extra_attributes) { { display_name: "Test_User_Login" } }

        it "should convert the identity_group#name field correctly" do
          post :create, user: user_attributes
          owner_uniq_name = User.find(created_instance_id("users")).identity_group.display_name
          expect(owner_uniq_name).to eq("Test_User_Login")
        end
      end

      context "with invalid user attributes" do
        let(:extra_attributes) { { display_name: nil } }

        it "should return 422" do
          post :create, user: user_attributes
          expect(response.status).to eq(422)
        end

        it "should not increase the count of users" do
          expect{ post :create, user: user_attributes }.not_to change{ User.count }
        end

        it "should not persist the user account" do
          post :create, user: user_attributes
          expect(User.where(display_name: user_attributes[:display_name])).to_not exist
        end

        it "should provide an error message in the response body" do
          post :create, user: user_attributes
          error_keys = %w(display_name identity_group.display_name)
          error_body = Hash[error_keys.zip(Array.new(3, ["can't be blank"]))]
          expect(response.body).to eq(json_error_message(error_body))
        end
      end

      context "when the password is too short" do

        let(:extra_attributes) { { password: "123456" } }

        it "should return 422" do
          post :create, user: user_attributes
          expect(response.status).to eq(422)
        end

        it "should not increase the count of users" do
          expect{ post :create, user: user_attributes }.not_to change{ User.count }
        end

        it "should provide an error message in the response body" do
          post :create, user: user_attributes
          error_body = { "password" => ["is too short (minimum is 8 characters)"] }
          expect(response.body).to eq(json_error_message(error_body))
        end

        it "should not orphan an identity User Group" do
          attrs = user_attributes.merge(display_name: "test_user", password: '123456')
          expect{ post :create, user: attrs }.not_to change{ UserGroup.count }
        end
      end
    end
  end

  context "as html", disabled: true do
    let(:user_params) { [ :email, :password, :password_confirmation, :display_name ] }

    before(:each) do
      request.env["HTTP_ACCEPT"] = "text/html"
    end

    describe "#create" do

      context "with valid user attributes" do
        let(:login) { "zoonser" }
        let(:extra_attributes) { { display_name: login } }

        it "should return redirect" do
          post :create, user: user_attributes
          expect(response.status).to eq(302)
        end

        it "should increase the count of users" do
          expect{ post :create, user: user_attributes }.to change{ User.count }.from(0).to(1)
        end

        it "should persist the user account" do
          post :create, user: user_attributes
          expect(User.find_by_display_name(login)).to_not be_nil
        end

        it "should sign the user in" do
          expect(subject).to receive(:sign_in)
          post :create, user: user_attributes
        end

        it "should create a new ZooniverseUser" do
          post :create, user: user_attributes
          expect(ZooniverseUser.where(login: login).first).to_not be_nil
        end

        context "when the user already exists in zooniverse_home" do
          let!(:existing_zoo_user) { create(:zooniverse_user, login: login) }

          it "should not create the panotpes user" do
            expect { post :create, user: user_attributes }.not_to change{ User.count }
          end
        end
      end

      context "with caps and spaces in the login name" do
        let(:login) { "Test_User_Login" }
        let(:extra_attributes) { { display_name: login } }

        it "should convert the identity_group#name field correctly" do
          post :create, user: user_attributes
          owner_uniq_name = User.find_by_display_name(login).identity_group.display_name
          expect(owner_uniq_name).to eq("Test_User_Login")
        end
      end

      context "with invalid user attributes" do
        let(:extra_attributes) { { display_name: nil } }

        it "should return 200" do
          post :create, user: user_attributes
          expect(response.status).to eq(200)
        end

        it "should not increase the count of users" do
          expect{ post :create, user: user_attributes }.not_to change{ User.count }
        end

        it "should not persist the user account" do
          post :create, user: user_attributes
          expect(User.where(display_name: user_attributes[:display_name])).to_not exist
        end
      end

      context "when the password is too short" do

        let(:extra_attributes) { { password: "123456" } }

        it "should return 200 with the new html view via respond_with behaviour" do
          post :create, user: user_attributes
          expect(response.status).to eq(200)
        end

        it "should not increase the count of users" do
          expect{ post :create, user: user_attributes }.not_to change{ User.count }
        end

        it "should not orphan an identity User Group" do
          attrs = user_attributes.merge(display_name: "test_user", password: '123456')
          expect{ post :create, user: attrs }.not_to change{ UserGroup.count }
        end
      end
    end
  end
end
