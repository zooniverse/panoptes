require 'spec_helper'

describe RegistrationsController, type: :controller do

  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "#create" do

    describe "with valid user attributes" do
      let(:user_attributes) { attributes_for(:user) }

      it "should return 201" do
        post :create, user: user_attributes
        expect(response.status).to eq(201)
      end

      it "should increase the count of users" do
        expect{ post :create, user: user_attributes }.to change{ User.count }.from(0).to(1)
      end

      it "should persist the user account" do
        post :create, user: user_attributes
        expect(User.where(login: user_attributes[:login])).to exist
      end

      it "should not sign the user in" do
        expect(subject).to_not receive(:sign_in)
        post :create, user: user_attributes
      end

      it "should clear the password attributes" do
        expect(subject).to receive(:clean_up_passwords)
        post :create, user: user_attributes
      end
    end

    describe "with invalid user attributes" do
      let(:user_attributes) { attributes_for(:user).merge(login: nil) }

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
    end
  end
end
