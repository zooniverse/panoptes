require 'spec_helper'

RSpec.describe Api::V1::OrganizationContentsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:api_resource_name) { 'organization_contents' }
  let(:api_resource_attributes) do
    %w(id title description introduction language)
  end
  let(:api_resource_links) { %w(organization_contents.organization) }

  let(:scopes) { %w(organization) }
  let!(:resource) do
    create(:organization_content, language: "en-CA", organization: organization)
  end
  let(:resource_class) { OrganizationContent }
  let(:primary_content) { organization.primary_content }

  describe "#index" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: organization,
             roles: ["collaborator"])
    end

    let!(:private_resource) do
      create(:organization, listed_at: nil)
        .organization_contents.first
    end

    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: organization,
             roles: ["translator"])
    end

    it_behaves_like "is showable"
  end

  describe "#create" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: organization,
             roles: ["collaborator"])
    end


    let(:create_params) do
      { organization_contents: {
          title: "A Bad Title",
          description: "Worse Content",
          introduction: "Useless Science",
          language: "en-CA",
          links: { organization: organization.id.to_s }
        }
      }
    end

    let(:test_attr) { :title }
    let(:test_attr_value) { "A Bad Title" }

    it_behaves_like "is creatable"
  end

  describe "#update" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: organization,
             roles: ["collaborator"])
    end


    let(:update_params) do
      { organization_contents: {
          title: "a bad title"
        }
      }
    end

    let(:test_attr) { :title }
    let(:test_attr_value) { "a bad title" }

    context "non-primary-language content" do
      it_behaves_like "is updatable"
    end

    context "primary-language content" do
      context "primary-langauge content" do

        before(:each) do
          default_request user_id: authorized_user.id, scopes: scopes
          params = update_params.merge(id: primary_content.id)
          put :update, params
        end

        it 'should return forbidden' do
          expect(response).to have_http_status(:not_found)
        end

        it 'should not update the content' do
          primary_content.reload
          expect(primary_content.title).to_not eq(test_attr_value)
        end
      end
    end
  end

  describe "#destroy" do
    let(:authorized_user) { organization.owner }
    context "non-primary-language content" do
      it_behaves_like "is destructable"
    end

    context "primary-langauge content" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        delete :destroy, id: primary_content.id
      end

      it 'should return forbidden' do
        expect(response).to have_http_status(:not_found)
      end

      it 'should not delete the content' do
        expect(OrganizationContent.find(primary_content.id)).to eq(primary_content)
      end
    end
  end

  describe "versioning" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: organization,
             roles: ["collaborator"])
    end


    let!(:existing_versions) { resource.versions.length }
    let(:num_times) { 11 }
    let(:update_proc) { Proc.new { |resource, n| resource.update!(title: n.to_s) } }
    let(:resource_param) { :organization_content_id }

    it_behaves_like "a versioned resource"
  end
end
