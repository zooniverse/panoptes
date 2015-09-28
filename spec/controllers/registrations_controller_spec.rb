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
      [ :email, :password, :password_confirmation, :login, :display_name,
        :global_email_communication, :project_email_communication,
        :beta_email_communication, :project_id ]
    end

    before(:each) do
      request.env["HTTP_ACCEPT"] = "application/json"
    end

    describe "#update" do
      let(:user) { create(:user) }

      context "with the correct old password" do
        let(:post_update) do
          sign_in user
          put :update, user: params
        end
        let(:params) do
          {
           password: 'testpassword',
           password_confirmation: 'testpassword',
           current_password: user.password
          }
        end

        it 'should set the new password' do
          post_update
          user.reload
          expect(user.valid_password?('testpassword')).to be_truthy
        end

        it 'should respond 204' do
          post_update
          expect(response).to have_http_status(:no_content)
        end

        it "should not call the subscribe worker" do
          expect(SubscribeWorker).not_to receive(:perform_async)
          post_update
        end
      end

      context "without the correct old password" do
        let(:params) do
          {
           password: 'testpassword',
           password_confirmation: 'testpassword',
           current_password: 'jamesbaxter'
          }
        end

        before(:each) do
          sign_in user
          put :update, user: params
        end

        it 'should not change the password' do
          user.reload
          expect(user.valid_password?('testpassword')).to be_falsy
        end

        it 'should respond 422' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with extra parameters" do
        let(:params) do
          {
           password: 'testpassword',
           password_confirmation: 'testpassword',
           current_password: user.password,
           email: 'ohno@example.com'
          }
        end

        before(:each) do
          sign_in user
          put :update, user: params
        end

        it 'should return 422' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "#create" do

      context "with valid user attributes" do
        let(:login) { "mcMMO-Dev" }
        let(:extra_attributes) { { login: login } }

        it "should return 201" do
          post :create, user: user_attributes
          expect(response.status).to eq(201)
        end

        it "should increase the count of users" do
          expect{ post :create, user: user_attributes }.to change{ User.count }.from(0).to(1)
        end

        it "should set the display name" do
          user_attributes.delete(:display_name)
          post :create, user: user_attributes
          expect(User.find(created_instance_id("users")).display_name).to eq(login)
        end

        it "should set the project_email_communication" do
          user_attributes.delete(:project_email_communication)
          post :create, user: user_attributes
          user = User.find(created_instance_id("users"))
          expect(user.project_email_communication).to eq(user.global_email_communication)
        end

        it "should persist the user account" do
          post :create, user: user_attributes
          expect(User.find(created_instance_id("users"))).to_not be_nil
        end

        it "should set the permitted params on the created user" do
          post :create, user: user_attributes
          user = User.find(created_instance_id("users"))
          user_attributes.except(:password).each do |attr, expected_value|
            expect(user.send(attr)).to eq(expected_value)
          end
        end

        it "should sign the user in" do
          expect(subject).to receive(:sign_in)
          post :create, user: user_attributes
        end

        it "should clear the password attributes" do
          expect(subject).to receive(:clean_up_passwords)
          post :create, user: user_attributes
        end

        it "should queue a welcome worker to send an email" do
          expect(UserWelcomeMailerWorker).to receive(:perform_async)
          post :create, user: user_attributes
        end

        context "with a project_id param" do
          let!(:extra_attributes) do
            { login: login, project_id: "1" }
          end

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
        end
      end

      context "when email communications are true" do
        let(:extra_attributes) { { login: 'asdfasdfasdf', global_email_communication: true } }

        it 'should call subscribe worker' do
          expect(SubscribeWorker).to receive(:perform_async).with(user_attributes[:email])
          post :create, user: user_attributes
        end

        context "when the resource doesn't save" do

          it 'should not call subscribe worker' do
            allow_any_instance_of(User).to receive(:persisted?).and_return(false)
            expect(SubscribeWorker).to_not receive(:perform_async)
            post :create, user: user_attributes
          end
        end
      end

      context "when email communications are false" do
        let(:extra_attributes) { { login: 'asdfasdf', global_email_communication: false } }
        it 'should not call subscribe worker' do
          expect(SubscribeWorker).to_not receive(:perform_async)
          post :create, user: user_attributes
        end
      end

      context "with caps and spaces in the display name" do
        let(:extra_attributes) { { login: "Test_User_Login" } }

        it "should convert the identity_group#name field correctly" do
          post :create, user: user_attributes
          owner_uniq_name = User.find(created_instance_id("users")).identity_group.name
          expect(owner_uniq_name).to eq("Test_User_Login")
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
          error_keys = %w(login display_name identity_group.display_name)
          errors = json_response['errors'].first['message']
          error_keys.each do |key|
            expect(errors[key]).to include "can't be blank"
          end
        end

        it "should not queue a welcome worker to send an email" do
          expect(UserWelcomeMailerWorker).to_not receive(:perform_async)
          post :create, user: user_attributes
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
          attrs = user_attributes.merge(login: "test_user", password: '123456')
          expect{ post :create, user: attrs }.not_to change{ UserGroup.count }
        end
      end
    end
  end

  context "as html" do
    let(:user_params) do
     [ :email, :password, :password_confirmation,
       :login, :global_email_communication ]
   end

    before(:each) do
      request.env["HTTP_ACCEPT"] = "text/html"
    end

    describe "#create" do

      context "with valid user attributes" do
        let(:login) { "zoonser" }
        let(:extra_attributes) { { login: login } }

        it "should return redirect" do
          post :create, user: user_attributes
          expect(response.status).to eq(302)
        end

        it "should increase the count of users" do
          expect{ post :create, user: user_attributes }.to change{ User.count }.from(0).to(1)
        end

        it "should persist the user account" do
          post :create, user: user_attributes
          expect(User.find_by_login(login)).to_not be_nil
        end

        it "should sign the user in" do
          expect(subject).to receive(:sign_in)
          post :create, user: user_attributes
        end

        it "should queue a welcome worker to send an email" do
          expect(UserWelcomeMailerWorker).to receive(:perform_async)
          post :create, user: user_attributes
        end
      end

      context "when email communications are true" do
        let(:extra_attributes) { { login: 'asdfasdf', global_email_communication: true } }
        it 'should call subscribe worker' do
          expect(SubscribeWorker).to receive(:perform_async).with(user_attributes[:email])
          post :create, user: user_attributes
        end
      end

      context "when email communications are true" do
        let(:extra_attributes) { { login: 'asdfasdf', global_email_communication: false } }
        it 'should call subscribe worker' do
          expect(SubscribeWorker).to_not receive(:perform_async)
          post :create, user: user_attributes
        end
      end

      context "with caps and spaces in the login name" do
        let(:login) { "Test_User_Login" }
        let(:extra_attributes) { { login: login } }

        it "should convert the identity_group#name field correctly" do
          post :create, user: user_attributes
          owner_uniq_name = User.find_by_login(login).identity_group.display_name
          expect(owner_uniq_name).to eq("Test_User_Login")
        end
      end

      context "with invalid user attributes" do
        let(:extra_attributes) { { login: nil } }

        it "should return 200" do
          post :create, user: user_attributes
          expect(response.status).to eq(200)
        end

        it "should not increase the count of users" do
          expect{ post :create, user: user_attributes }.not_to change{ User.count }
        end

        it "should not persist the user account" do
          post :create, user: user_attributes
          expect(User.where(login: user_attributes[:login])).to_not exist
        end

        it "should not queue a welcome worker to send an email" do
          expect(UserWelcomeMailerWorker).to_not receive(:perform_async)
          post :create, user: user_attributes
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
          attrs = user_attributes.merge(login: "test_user", password: '123456')
          expect{ post :create, user: attrs }.not_to change{ UserGroup.count }
        end
      end
    end
  end
end
