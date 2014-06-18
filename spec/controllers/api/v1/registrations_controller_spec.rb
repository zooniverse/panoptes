require 'spec_helper'

describe Api::V1::RegistrationsController, type: :controller, focus: true do

  describe "#new" do

    it "should return 404" do
      get :new
      expect(response.status).to eq(404)
    end
  end

  describe "#edit" do

    it "should return 404" do
      get :edit
      expect(response.status).to eq(404)
    end
  end

  describe "#create" do

    describe "with valid user attributes" do
      let(:user_attributes) { attributes_for(:user) }

      it "should return 200" do
        post :create, user: user_attributes
        expect(response.status).to eq(404)
      end

      it "should increase the count of users" do
        expect{ post :create, user: user_attributes }.to change{ User.count }.from(0).to(1)
      end

      it "should persist the user account" do
        post :create, user: user_attributes
        expect(User.where(login: user_attributes[:login]).first).to exist
      end
    end

    describe "with invalid user attributes" do
      let(:user_attributes) { attributes_for(:user).merge(email: nil, login: nil) }

      it "should return 400" do
        post :create, user: user_attributes
        expect(response.status).to eq(400)
      end

      it "should increase the count of users" do
        expect{ post :create, user: user_attributes }.to change{User.count}.from(0).to(1)
      end

      it "should persist the user account" do
        post :create, user: user_attributes
        expect(User.where(login: user_attributes[:login]).first).to exist
      end
    end
  end

  describe "#update" do
    let(:user) { create(:user) }

    describe "patch" do

      it "should return 404" do
        patch :update, id: user.id
        expect(response.status).to eq(404)
      end
    end

    describe "put" do

      it "should return 404" do
        put :update, id: user.id, user: {}
        expect(response.status).to eq(404)
      end
    end
  end

  describe "#destroy" do

    it "should return 404" do
      user = create(:user)
      delete :destroy, id: user.id
      binding.pry
      expect(response.status).to eq(404)
    end
  end
end
