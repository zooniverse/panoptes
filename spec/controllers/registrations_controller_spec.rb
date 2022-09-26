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
          put :update, params: { user: params }
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

        it "should queue a mailer worker" do
          expect(UserInfoChangedMailerWorker).to receive(:perform_async).with(user.id, "password")
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
          put :update, params: { user: params }
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
           project_id: 123
          }
        end

        before(:each) do
          sign_in user
          put :update, params: { user: params }
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
          post :create, params: { user: user_attributes }
          expect(response.status).to eq(201)
        end

        it "should increase the count of users" do
          expect{ post :create, params: { user: user_attributes } }.to change{ User.count }.from(0).to(1)
        end

        it "should set the display name" do
          user_attributes.delete(:display_name)
          post :create, params: { user: user_attributes }
          expect(User.find(created_instance_id("users")).display_name).to eq(login)
        end

        it "should set the project_email_communication" do
          user_attributes.delete(:project_email_communication)
          post :create, params: { user: user_attributes }
          user = User.find(created_instance_id("users"))
          expect(user.project_email_communication).to eq(user.global_email_communication)
        end

        it "should persist the user account" do
          post :create, params: { user: user_attributes }
          expect(User.find(created_instance_id("users"))).to_not be_nil
        end

        it "should set the permitted params on the created user" do
          post :create, params: { user: user_attributes }
          user = User.find(created_instance_id("users"))
          user_attributes.except(:password).each do |attr, expected_value|
            expect(user.send(attr)).to eq(expected_value)
          end
        end

        it "should sign the user in" do
          expect(subject).to receive(:sign_in)
          post :create, params: { user: user_attributes }
        end

        it "should clear the password attributes" do
          expect(subject).to receive(:clean_up_passwords)
          post :create, params: { user: user_attributes }
        end

        it "should queue a welcome worker to send an email" do
          expect(UserWelcomeMailerWorker).to receive(:perform_async)
          post :create, params: { user: user_attributes }
        end

        context "with a project_id param" do
          let(:project) { create :project }
          let!(:extra_attributes) do
            { login: login, project_id: project.id.to_s }
          end

          it "should return 201" do
            post :create, params: { user: user_attributes }
            expect(response.status).to eq(201)
          end

          it "should increase the count of users" do
            expect{ post :create, params: { user: user_attributes } }.to change{ User.count }.by(1)
          end

          it "should persist the user account" do
            post :create, params: { user: user_attributes }
            expect(User.find(created_instance_id("users"))).to_not be_nil
          end
        end
      end

      context "with caps and spaces in the display name" do
        let(:extra_attributes) { { login: "Test_User_Login" } }

        it "should convert the identity_group#name field correctly" do
          post :create, params: { user: user_attributes }
          owner_uniq_name = User.find(created_instance_id("users")).identity_group.name
          expect(owner_uniq_name).to eq("Test_User_Login")
        end
      end

      context "with invalid user attributes" do
        let(:extra_attributes) { { login: nil } }

        it "should return 422" do
          post :create, params: { user: user_attributes }
          expect(response.status).to eq(422)
        end

        it "should not increase the count of users" do
          expect{ post :create, params: { user: user_attributes } }.not_to change{ User.count }
        end

        it "should not persist the user account" do
          post :create, params: { user: user_attributes }
          expect(User.where(login: user_attributes[:login])).to_not exist
        end

        it "should provide an error message in the response body" do
          post :create, params: { user: user_attributes }
          error_keys = %w(login display_name identity_group.display_name)
          errors = json_response['errors'].first['message']
          error_keys.each do |key|
            expect(errors[key]).to include "can't be blank"
          end
        end

        it "should not queue a welcome worker to send an email" do
          expect(UserWelcomeMailerWorker).to_not receive(:perform_async)
          post :create, params: { user: user_attributes }
        end
      end

      context "when the password is too short" do

        let(:extra_attributes) { { password: "123456" } }

        it "should return 422" do
          post :create, params: { user: user_attributes }
          expect(response.status).to eq(422)
        end

        it "should not increase the count of users" do
          expect{ post :create, params: { user: user_attributes } }.not_to change{ User.count }
        end

        it "should provide an error message in the response body" do
          post :create, params: { user: user_attributes }
          error_body = { "password" => ["is too short (minimum is 8 characters)"] }
          expect(response.body).to eq(json_error_message(error_body))
        end

        it "should not orphan an identity User Group" do
          attrs = user_attributes.merge(login: "test_user", password: '123456')
          expect{ post :create, params: { user: attrs } }.not_to change{ UserGroup.count }
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
          post :create, params: { user: user_attributes }
          expect(response.status).to eq(302)
        end

        it "should increase the count of users" do
          expect{ post :create, params: { user: user_attributes } }.to change{ User.count }.from(0).to(1)
        end

        it "should persist the user account" do
          post :create, params: { user: user_attributes }
          expect(User.find_by_login(login)).to_not be_nil
        end

        it "should sign the user in" do
          expect(subject).to receive(:sign_in)
          post :create, params: { user: user_attributes }
        end

        it "should queue a welcome worker to send an email" do
          expect(UserWelcomeMailerWorker).to receive(:perform_async)
          post :create, params: { user: user_attributes }
        end
      end

      context "with caps and spaces in the login name" do
        let(:login) { "Test_User_Login" }
        let(:extra_attributes) { { login: login } }

        it "should convert the identity_group#name field correctly" do
          post :create, params: { user: user_attributes }
          owner_uniq_name = User.find_by_login(login).identity_group.display_name
          expect(owner_uniq_name).to eq("Test_User_Login")
        end
      end

      context "with invalid user attributes" do
        let(:extra_attributes) { { login: nil } }

        it "should return 200" do
          post :create, params: { user: user_attributes }
          expect(response.status).to eq(200)
        end

        it "should not increase the count of users" do
          expect{ post :create, params: { user: user_attributes } }.not_to change{ User.count }
        end

        it "should not persist the user account" do
          post :create, params: { user: user_attributes }
          expect(User.where(login: user_attributes[:login])).to_not exist
        end

        it "should not queue a welcome worker to send an email" do
          expect(UserWelcomeMailerWorker).to_not receive(:perform_async)
          post :create, params: { user: user_attributes }
        end
      end

      context "when the password is too short" do

        let(:extra_attributes) { { password: "123456" } }

        it "should return 200 with the new html view via respond_with behaviour" do
          post :create, params: { user: user_attributes }
          expect(response.status).to eq(200)
        end

        it "should not increase the count of users" do
          expect{ post :create, params: { user: user_attributes } }.not_to change{ User.count }
        end

        it "should not orphan an identity User Group" do
          attrs = user_attributes.merge(login: "test_user", password: '123456')
          expect{ post :create, params: { user: attrs } }.not_to change{ UserGroup.count }
        end
      end
    end

    describe '#destroy' do
      let(:password) { 'password' }
      let(:user) { create :user, password: password }
      let(:user_id) { user.id }
      let(:access_token) { create(:access_token, resource_owner_id: user_id) }

      before(:each) do
        sign_in user
        request.env["HTTP_ACCEPT"] = "text/html"
      end

      context 'with correct password' do
        it 'redirects to root' do
          delete :destroy, params: { user: {current_password: password} }
          expect(response).to redirect_to('/')
          expect(flash[:notice]).to be_present
        end

        it 'signs out the user' do
          expect(controller).to receive(:sign_out)
          delete :destroy, params: { user: {current_password: password} }
        end

        it 'deactivates the user' do
          delete :destroy, params: { user: {current_password: password} }
          expect(user.reload.active?).to be_falsey
        end

        it 'scrubs the users information' do
          expect(UserInfoScrubber).to receive(:scrub_personal_info!).with(user)
          delete :destroy, params: { user: {current_password: password} }
        end
      end

      context 'with incorrect password' do
        it 'renders error' do
          delete :destroy, params: { user: {current_password: 'wrong'} }
          expect(user.reload.active?).to be_truthy
          expect(flash[:delete_alert]).to be_present
        end
      end

      let(:authorized_user) { user }
      let(:resource) { user }
      let(:instances_to_disable) do
        [resource] |
          resource.projects |
          resource.memberships |
          resource.collections
      end
    end
  end
end
