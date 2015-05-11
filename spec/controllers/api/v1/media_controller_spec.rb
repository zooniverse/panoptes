require 'spec_helper'

RSpec.describe Api::V1::MediaController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:api_resource_name){ 'media' }
  let(:resource_class) { Medium }
  let(:api_resource_attributes) { %w(id src media_type) }
  let(:api_resource_links) { [] }
  let(:scopes) { %w(public medium) }

  RSpec.shared_examples "has_many media" do |parent_name, media_type|
    describe "#index" do
      let(:private_resource) { create(:project, private: true).avatar }
      let(:n_visisble) { 2 }

      it_behaves_like 'is indexable'
    end

    describe "#show" do
      it_behaves_like "is showable"
    end

    describe "#destroy" do
      it_behaves_like "is destructable"
    end

    describe "#create" do
      let(:test_attr) { :type }
      let(:test_attr_value) { :project_avatar }
      let(:create_params) do
        {
         media: { content_type: "image/jpeg" }
        }

        it_behaves_like "is creatable"
      end
    end

    describe "#update" do
      let(:test_attr) { :content_type }
      let(:test_attr_value) { "image/png" }
      let(:update_params) do
        {
         media: { content_type: "image/png" }
        }
      end

      it_behaves_like "is updatable"
    end
  end

  RSpec.shared_examples "has_one media" do |parent_name, media_type|
    describe "#index" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        get :index, :"#{parent_name}_id" => parent.id, :media_name => media_type
      end

      it 'should return ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'should include 1 item' do
        expect(json_response["media"].length).to eq(1)
      end

      it_behaves_like "an api response"
    end

    describe "#create" do
      let!(:resource) { parent.send(media_type) }
      let(:resource_url) { "http://test.host/api/#{parent_name}s/#{parent.id}/#{media_type}" }
      let(:test_attr) { :type }
      let(:test_attr_value) { "#{parent_name}_#{media_type}" }
      let(:new_resource) { resource_class.find(created_instance_id(api_resource_name)) }
      let(:create_params) do
        params = {
                  media: { content_type: "image/jpeg" }
                 }
        params.merge(:"#{parent_name}_id" => parent.id, :media_name => media_type)
      end

      it_behaves_like "is creatable"

      it "should return the medium's put url" do
        default_request user_id: authorized_user.id, scopes: scopes
        post :create, create_params
        expect(json_response["media"][0]["src"]).to eq(new_resource.put_url)
      end

      describe "updates relationship" do
        before(:each) do
          default_request user_id: authorized_user.id, scopes: scopes
          post :create, create_params
        end

        it "should replace the old media" do
          parent.reload
          expect(parent.send(media_type)).to eq(new_resource)
        end

        it "should destroy the old media" do
          expect{ resource.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "parent is a project" do
    let(:project) { create(:project, owner: authorized_user) }
    let(:resources) { [project.avatar, project.background] }
    let(:parent) { project }

    it_behaves_like "has_one media", :project, :avatar
    it_behaves_like "has_one media", :project, :background
  end

  describe "parent is a user" do
    let(:parent) { authorized_user }
    let(:resources) { [authorized_user.avatar] }

    it_behaves_like "has_one media", :user, :avatar
  end
end
