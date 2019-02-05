require 'spec_helper'

describe Api::V1::OrganizationsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:api_resource_name) { "organizations" }
  let(:organization) { build(:organization, listed_at: Time.now, owner: authorized_user) }
  let(:unlisted_organization) { build(:unlisted_organization) }
  let(:owned_unlisted_organization) { build(:unlisted_organization, owner: authorized_user) }

  let(:api_resource_name) { "organizations" }
  let(:api_resource_links) do
    [ "organizations.projects",
      "organizations.organization_roles",
      "organizations.avatar",
      "organizations.background",
      "organizations.pages",
      "organizations.owner",
      "organizations.attached_images" ]
  end
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

  describe "with a logged in user" do
    describe "#index" do
      it_behaves_like "is indexable" do
        let(:private_resource) { unlisted_organization }
        let(:api_resource_attributes) { %w(id display_name) }
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

      it_behaves_like "indexable by tag" do
        let(:resource) { organization }
        let(:second_resource) { build(:organization, listed_at: Time.now, owner: authorized_user) }
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
            introduction: "org intro",
            announcement: "We dont exist",
            urls: [{label: "Blog", url: "http://blogo.com/example"}],
            primary_language: "zh-tw",
            categories: %w(stuff things moar)
          }
        }
      end

      it_behaves_like "is creatable" do
        let(:test_attr) { :display_name }
        let(:test_attr_value) { "The Illuminati" }
        let(:resource_class) { Organization }
        let(:api_resource_attributes) { %w(id display_name) }
        let(:api_resource_links) { %w() }

        context "a logged in user" do
          before(:each) do
            default_request scopes: scopes, user_id: authorized_user.id
            post :create, create_params
          end
          let(:test_attr) { :categories }
          let(:expected_categories) do
            create_params.dig(:organizations, :categories)
          end

          # this should really be a spec on the operation to create orgs :sadpanda:
          it 'should create the organization with the categories' do
            categories = resource_class.find(created_id).send(test_attr)
            expect(categories).to match_array(expected_categories)
          end

          it 'should set content attributes on the main model' do
            resource = resource_class.find(created_id)
            expect(resource.title).to eq("The Illuminati")
            expect(resource.description).to eq("This organization is the most organized organization to ever organize")
            expect(resource.introduction).to eq("org intro")
            expect(resource.url_labels).to eq({"0.label" => "Blog"})
            expect(resource.announcement).to eq("We dont exist")
          end
        end
      end

      it_behaves_like "it syncs the resource translation strings", non_translatable_attributes_possible: false do
        let(:translated_klass_name) { Organization.name }
        let(:translated_resource_id) { be_kind_of(Integer) }
        let(:translated_language) { create_params.dig(:organizations, :primary_language) }
        let(:controller_action) { :create }
        let(:translatable_action_params) { create_params }
      end
    end

    describe "#update" do
      let(:language) { "tw" }
      let(:resource) do
        create(:organization, owner: authorized_user, primary_language: language)
      end
      let(:update_params) do
        {
          organizations: {
            primary_language: language,
            display_name: "Def Not Illuminati",
            description: "This Organization is not affiliated with the Illuminati, absolutely not no way",
            urls: [{label: "Blog", url: "http://blogo.com/example"}],
            introduction: "Hello and welcome to Illuminati Headquarters oh wait damn",
            announcement: "Hear Ye, Hear Ye"
          }
        }
      end

      it_behaves_like "is updatable" do
        let(:resource_class) { Organization }
        let(:api_resource_attributes) { ["display_name", "description"] }
        let(:api_resource_links) { [] }
        let(:test_attr) { :display_name }
        let(:test_attr_value) { "Def Not Illuminati" }
      end

      it_behaves_like "has updatable tags" do
        let(:tag_array) { ["astro", "gastro"] }
        let(:tag_params) do
          { organizations: { tags: tag_array }, id: resource.id }
        end
      end

      it_behaves_like "it syncs the resource translation strings" do
        let(:translated_klass_name) { resource.class.name }
        let(:translated_resource_id) { resource.id }
        let(:translated_language) { resource.primary_language }
        let(:controller_action) { :update }
        let(:translatable_action_params) { update_params.merge(id: resource.id) }
        let(:non_translatable_action_params) { {id: resource.id, organizations: {listed: true}} }
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

      context "as a logged in user" do
        before do
          default_request scopes: scopes, user_id: authorized_user.id
          organization.save!
        end

        def run_update(params)
          put :update, params
        end

        it "updates the title to match the display name" do
          params = { organizations: { display_name: "Also a title"}, id: organization.id }
          run_update(params)
          expect(json_response["organizations"].first['title']).to eq("Also a title")
        end

        it "touches listed_at if listed is true" do
          organization.update_attributes({listed: false, listed_at: nil})
          params = { organizations: { listed: true }, id: organization.id }
          run_update(params)
          expect(json_response["organizations"].first['listed_at']).to be_truthy
        end

        it "nulls listed_at if listed is false" do
          organization.update_attributes({listed: true, listed_at: Time.now })
          params = { organizations: { listed: false }, id: organization.id }
          run_update(params)
          expect(json_response["organizations"].first['listed_at']).to be_nil
        end

        it "updates the categories" do
          new_categories = %w(fish snails worms)
          organization.update_attributes({listed: true, listed_at: Time.now })
          params = {
            organizations: {
              categories: new_categories
            },
            id: organization.id
          }
          run_update(params)
          response_categories = json_response["organizations"].first['categories']
          expect(response_categories).to match_array(new_categories)
        end
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
