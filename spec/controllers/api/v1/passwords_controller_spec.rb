require 'spec_helper'

describe Api::V1::PasswordsController, type: [ :controller, :mailer ] do

  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "#create" do
    let(:user) { create(:user) }

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

    context "using an email address that belongs to a user" do
      let(:email_attributes) { user.attributes.slice("email") }
      let(:user_email_attrs) { { user: email_attributes } }

      it "should return 200" do
        post :create, user_email_attrs
        expect(response.status).to eq(200)
      end

      it "should use devise to send the password reset email" do
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
end
