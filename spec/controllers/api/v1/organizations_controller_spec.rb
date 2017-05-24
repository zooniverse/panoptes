require 'spec_helper'

describe Api::V1::OrganizationsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:organization) { build(:organization, listed_at: Time.now, owner: authorized_user) }
  let(:unlisted_organization) { build(:organization, listed_at: nil) }
  let(:owned_unlisted_organization) { build(:organization, listed_at: nil, owner: authorized_user) }

  let(:scopes) { %w(public organization) }

  describe "when not logged in" do
    describe "#index" do
      it "returns only the listed organization" do
        organization.save
        owned_unlisted_organization.save
        get :index
        expect(response.status).to eq(200)
        expect(json_response["organizations"].length).to eq(1)
        expect(json_response["organizations"].map { |o| o['id'] }).not_to include(owned_unlisted_organization.id.to_s)
      end
    end
  end

  describe "when a logged in user" do
    describe "#index" do
      it_behaves_like "is indexable" do
        let(:private_resource) { unlisted_organization }
        let(:api_resource_name) { "organizations" }
        let(:api_resource_attributes) { %w(id display_name) }
        let(:api_resource_links) { %w() }

        let(:n_visible) { 1 }

        before do
          organization.save
          private_resource.save
        end
      end

      it "returns listed organizations" do
        organization.save
        get :index
        expect(response.status).to eq(200)
        expect(json_response["organizations"].map { |o| o['id'] }).to include(organization.id.to_s)
      end

      describe "with unlisted organizations" do
        let(:unauthorized_user) { create(:user) }

        before do
          unlisted_organization.save
          owned_unlisted_organization.save
        end

        it "returns unlisted organizations that I own" do
          default_request scopes: scopes, user_id: authorized_user.id
          get :index
          expect(json_response["organizations"].map { |o| o['id'] }).to include(owned_unlisted_organization.id.to_s)
        end

        it "doesn't return unlisted organizations for unauthorized users" do
          default_request scopes: scopes, user_id: unauthorized_user.id
          get :index
          expect(json_response["organizations"]).to be_empty
        end
      end

      describe "filtering by slug" do
        let(:index_options) { { slug: organization.slug } }
        it "filters by slug" do
          organization.save
          owned_unlisted_organization.save

          default_request scopes: scopes, user_id: authorized_user.id
          get :index, index_options
          expect(json_response["organizations"].length).to eq(1)
        end
      end
    end

    describe "#show" do
      before { organization.save }

      it_behaves_like "is showable" do
        let(:resource) { organization }
        let(:api_resource_name) { "organizations" }
        let(:api_resource_attributes) { %w(id display_name) }
        let(:api_resource_links) { %w() }
      end
    end

    describe "#create" do
      let(:create_params) do
        {
          organizations: {
            display_name: "The Illuminati",
            description: "This organization is the most organized organization to ever organize",
            urls: [{label: "Blog", url: "http://blogo.com/example"}],
            primary_language: "zh-tw"
          }
        }
      end

      it_behaves_like "is creatable" do
        let(:test_attr) { :display_name }
        let(:test_attr_value) { "The Illuminati" }
        let(:resource_class) { Organization }
        let(:api_resource_name) { "organizations" }
        let(:api_resource_attributes) { %w(id display_name) }
        let(:api_resource_links) { %w() }
      end
    end

    describe "#update" do
      it_behaves_like "is updatable" do
        let(:resource) { create(:organization, owner: authorized_user) }
        let(:resource_class) { Organization }
        let(:api_resource_name) { "organizations" }
        let(:api_resource_attributes) { ["display_name", "description"] }
        let(:api_resource_links) { [] }
        let(:update_params) do
          {
            organizations: {
              primary_language: "tw",
              display_name: "Def Not Illuminati",
              description: "This Organization is not affiliated with the Illuminati, absolutely not no way",
              urls: [{label: "Blog", url: "http://blogo.com/example"}],
              introduction: "Hello and welcome to Illuminati Headquarters oh wait damn"
            }
          }
        end
        let(:test_attr) { :display_name }
        let(:test_attr_value) { "Def Not Illuminati" }
      end

      context "includes exceptional parameters" do
        let(:incomplete_params) do
          {
            organizations: {
              display_name: "Just a name"
            }
          }
        end

        before do
          default_request scopes: scopes, user_id: authorized_user.id
          organization.save!
        end

        after do
          expect(response).to have_http_status(:ok)
          expect(json_response["organizations"].length).to eq(1)
        end

        it "successfully updates with incomplete params", :aggregate_failures do
          params = incomplete_params.merge(id: organization.id)
          put :update, params
        end

        it "successfully updates with nested params", :aggregate_failures do
          params = incomplete_params.merge(id: organization.id)
          params[:organizations][:urls] = [
            {label: "Blog", url: "http://blogo.com/example"},
            {label: "Slog", url: "http://whattasite.net"},
            {label: "Krog", url: "http://potatosalad.yum"}
          ]
          put :update, params
        end
      end

      it "updates the title to match the display name" do
        default_request scopes: scopes, user_id: authorized_user.id
        organization.save!
        params = { organizations: { display_name: "Also a title"}, id: organization.id }
        put :update, params
        expect(json_response["organizations"].first['title']).to eq("Also a title")
      end
    end

    describe "#destroy" do
      let(:resource) { create(:organization, owner: authorized_user) }
      let(:instances_to_disable) { [resource] }

      it_behaves_like "is deactivatable"
    end

    describe "#update_links" do
      let(:resource) { create(:organization, owner: authorized_user) }
      let(:resource_id) { :organization_id }
      let(:test_attr) { :display_name }
      let(:test_relation_ids) { [ linked_resource.id.to_s ] }

      describe "linking a project" do
        let!(:linked_resource) { create(:project) }
        let(:test_relation) { :projects }
        let(:expected_copies_count) { 1 }

        it_behaves_like "supports update_links"
      end
    end
  end
end
