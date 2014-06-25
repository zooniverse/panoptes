require 'spec_helper'

describe Api::V1::PasswordsController, type: [ :controller, :mailer ] do

  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "#create" do
    let(:user) { create(:user) }
    let(:email_attributes) { user.attributes.slice("email") }
    let(:user_email_attrs) { { user: email_attributes } }

    context "when not supplying an email" do

      it "should return 422" do
        post :create, user: { email: nil }
        expect(response.status).to eq(422)
      end
    end

    context "using an email address that doesn't belong to a user" do

      before(:each) do
        post :create, user: { email: 'not_a_user@test.com' }
      end

      it "should return 422" do
        expect(response.status).to eq(422)
      end

      it "should not send an email to the account email address" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when the user is disabled" do
      let!(:disable_user) { user.disable! }

      it "should respond with 422" do
        post :create, user_email_attrs
        expect(response.status).to eq(422)
      end

      it "should not send an email to the account email address" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when the user was created using third party authentication" do
      #rework when third party authentication is added in (currently req a password)
      let!(:user) do
        user = build(:omni_auth_user)
        user.save(validate: false)
        user
      end

      it "should respond with 422" do
        post :create, user_email_attrs
        expect(response.status).to eq(422)
      end

      it "should not send an email to the account email address" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "using an email address that belongs to a user" do

      it "should return 200" do
        post :create, user_email_attrs
        expect(response.status).to eq(200)
      end

      it "should use devise to send the password reset email" do
        Api::V1::PasswordsController.any_instance.stub(:successfully_sent?).and_return(:true)
        expect(User).to receive(:send_reset_password_instructions).once
        post :create, user_email_attrs
      end

      it "should send an email" do
        post :create, user_email_attrs
        expect(ActionMailer::Base.deliveries).to_not be_empty
      end

      it "should send an email from the no-reply email address" do
        post :create, user_email_attrs
        email = ActionMailer::Base.deliveries.first
        expect(email.from).to include("no-reply@zooniverse.org")
      end

      it "should send an email to the account email address" do
        post :create, user_email_attrs
        email = ActionMailer::Base.deliveries.first
        expect(email.to).to include(user.email)
      end
    end
  end

  describe "#update" do
    let(:user) { create(:user) }
    let(:new_password) { "87654321" }
    let(:passwords) do
      { password: new_password, password_confirmation: new_password }
    end

    context "when not supplying a valid reset token" do

      it "should return 422" do
        put :update, user: { reset_password_token: "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        expect(response.status).to eq(422)
      end
    end

    context "when supplying a valid reset token" do
      let(:valid_token) { user.send_reset_password_instructions }

      context "with a database user" do

        before(:each) do
          put :update, user: passwords.merge(reset_password_token: valid_token)
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should update the password" do
          user.reload
          expect(user.valid_password?(new_password)).to eq(true)
        end
      end
    end
  end
end
