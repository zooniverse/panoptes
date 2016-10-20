require 'spec_helper'

describe Api::V1::OrganizationsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:organization) { build(:organization, listed_at: Time.now, owner: authorized_user) }

  let(:scopes) { %w(public organization) }

  describe '#index' do
    it_behaves_like "is indexable" do
      let(:api_resource_name) { 'organizations' }
      let(:api_resource_attributes) { %w(id name display_name) }
      let(:api_resource_links) { %w() }

      let!(:private_resource) { create(:organization, listed_at: nil) }
      let(:n_visible) { 1 }

      before { organization.save }
    end

    it 'returns listed organizations' do
      organization.save
      get :index
      expect(response.status).to eq(200)
      expect(json_response["organizations"][0]["id"]).to eq(organization.id.to_s)
    end

    describe "with unlisted organizations" do
      let!(:unlisted_org) { create(:organization, listed_at: nil, owner: authorized_user)}
      it 'returns unlisted organizations that I am a collaborator on' do
        default_request scopes: scopes, user_id: authorized_user.id
        get :index
        expect(json_response["organizations"][0]["id"]).to eq(unlisted_org.id.to_s)
      end

      it "doesn't return unlisted organizations for unauthorized users" do
        get :index
        expect(json_response["organizations"]).to be_empty
      end
    end
  end

  describe "#show" do
    before { organization.save }

    it_behaves_like "is showable" do
      let(:resource) { organization }
      let(:api_resource_name) { 'organizations' }
      let(:api_resource_attributes) { %w(id name display_name) }
      let(:api_resource_links) { %w() }
    end
  end

  describe "#create" do
    let(:create_params) do
      {
        organizations: {
          name: "The Illuminati",
          display_name: "The Illuminati",
          title: 'Come join us',
          description: "This organization is the most organized organization to ever organize",
          primary_language: "zh-tw"
        }
      }
    end

    it_behaves_like "is creatable" do
      let(:test_attr) { :display_name }
      let(:test_attr_value) { "The Illuminati" }
      let(:resource_class) { Organization }
      let(:api_resource_name) { 'organizations' }
      let(:api_resource_attributes) { %w(id name display_name) }
      let(:api_resource_links) { %w() }
    end
  end

  describe "#update" do
    it_behaves_like "is updatable" do
      let(:resource) { create(:organization, owner: authorized_user) }
      let(:resource_class) { Organization }
      let(:api_resource_name) { "organizations" }
      let(:api_resource_attributes) { ["name", "display_name", "title", "description"] }
      let(:api_resource_links) { [] }
      let(:update_params) do
        {
          organizations: {
            id: resource.id,
            primary_language: "tw",
            name: "A Different Name",
            display_name: "Def Not Illuminati",
            title: "Totally Harmless",
            description: "This Organization is not affiliated with the Illuminati, absolutely not no way",
            introduction: "Hello and welcome to Illuminati Headquarters oh wait damn"
          }
        }
      end
      let(:test_attr) { :display_name }
      let(:test_attr_value) { "Def Not Illuminati" }
    end
  end

  describe "#destroy" do
    let(:resource) { create(:organization, owner: authorized_user) }
    let(:instances_to_disable) { [resource] }

    it_behaves_like "is deactivatable"
  end
end