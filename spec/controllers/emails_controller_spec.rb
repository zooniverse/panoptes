require 'spec_helper'

describe EmailsController, type: :controller do

  shared_examples "it removes user email subscriptions" do

    it "should redirect to the unsubscribed success page" do
      unsubscribe_user
      expect(response).to redirect_to("#{base_url}")
    end

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

    context "when the user subscriptions can't be updated" do
      before(:each) do
        allow(subject).to receive(:revoke_email_subscriptions).and_return(false)
      end

      it "should redirect to the unsubscribed failure page" do
        unsubscribe_user
        expect(response).to redirect_to("#{base_url}?failed=true")
      end

      it 'should not queue an unsubscribe maillist worker' do
        expect(UnsubscribeWorker).to_not receive(:perform_async)
        unsubscribe_user
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
  let(:base_url) { "http://localhost:2727/#/unsubscribed" }

  context "html" do

    describe "#unsubscribe via token" do

      context "when not supplying a token" do

        it "should return 422" do
          get :unsubscribe
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when supplying an invalid token" do

        it "should return 422" do
          get :unsubscribe, token: "blurghkjsh"
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when supplying a valid token" do
        let(:unsubscribe_user) do
          get :unsubscribe, token: user.unsubscribe_token
        end

        it_behaves_like "it removes user email subscriptions"
      end
    end
  end

  context "json" do

    describe "#unsubscribe via email" do

      let(:unsubscribe_user) do
        get :unsubscribe, token: user.unsubscribe_token
      end

      before(:each) do
        request.env["HTTP_ACCEPT"] = "application/json"
        request.env["CONTENT_TYPE"] = "application/json"
      end

      context "when not supplying a email" do

        it "should return 422" do
          get :unsubscribe
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when supplying an invalid email" do

        it "should return 422" do
          get :unsubscribe, email: "not@my.email"
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when supplying a valid email" do
        let(:unsubscribe_user) do
          get :unsubscribe, email: user.email
        end

        it_behaves_like "it removes user email subscriptions"
      end
    end
  end
end
