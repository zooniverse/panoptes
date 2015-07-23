require 'spec_helper'

describe EmailsController, type: :controller do

  shared_examples "it removes user email subscriptions" do

    it "should set all the user *_email_communication fields to false" do
      unsubscribe_user
      user.reload
      email_attrs.keys.each do |email_attribute|
        expect(user.send(email_attribute)).to eq(false)
      end
    end

    it 'should queue an unsubscribe maillist worker' do
      expect(UnsubscribeWorker).to receive(:perform_async).with(user.email)
      unsubscribe_user
    end

    context "when the user has user project preferences" do
      let!(:upp) do
        create_list(:user_project_preference, 3, user: user)
      end

      it "should set all the user_project_preferences email_communication to false" do
        unsubscribe_user
        upp_emails = UserProjectPreference.where(user_id: user.id)
          .map(&:email_communication).uniq
        expect(upp_emails).to match_array([false])
      end
    end
  end

  let(:user) { create(:user, email_attrs) }
  let(:email_attrs) do
    {
      global_email_communication: true,
      project_email_communication: true,
      beta_email_communication: true
    }
  end
  let(:base_url) { "http://localhost:2727/#/unsubscribe" }

  context "html" do

    describe "#unsubscribe via token" do

      context "when not supplying a token" do

        it "should redirect to the unsubscribe page" do
          get :unsubscribe_via_token
          expect(response.location).to eq(base_url)
        end
      end

      context "when supplying an invalid token" do
        let(:token) { "blurghkjsh" }

        it "should redirect" do
          get :unsubscribe_via_token, token: token
          expect(response.location).to eq("#{base_url}?processed=true")
        end

        it "should redirect to the front end unsubscribed page" do
          get :unsubscribe_via_token, token: token
          expect(response.location).to eq("#{base_url}?processed=true")
        end
      end

      context "when supplying a valid token" do
        let(:token) { user.unsubscribe_token }
        let(:unsubscribe_user) do
          get :unsubscribe_via_token, token: token
        end

        it_behaves_like "it removes user email subscriptions"

        it "should redirect to the unsubscribed success page" do
          unsubscribe_user
          expect(response.location).to eq("#{base_url}?processed=true")
        end
      end
    end
  end

  context "json" do

    describe "#unsubscribe via email" do

      before(:each) do
        request.env["HTTP_ACCEPT"] = "application/json"
        request.env["CONTENT_TYPE"] = "application/json"
      end

      context "when not supplying a email" do

        it "should return 422" do
          post :unsubscribe_via_email
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when supplying an invalid email" do

        it "should be successful" do
          post :unsubscribe_via_email, email: "not@my.email"
          expect(response).to have_http_status(:ok)
        end
      end

      context "when supplying a valid email" do
        let(:unsubscribe_user) do
          post :unsubscribe_via_email, email: user.email
        end

        it_behaves_like "it removes user email subscriptions"
      end
    end
  end
end
