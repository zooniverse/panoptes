require 'spec_helper'

describe Api::V1::MembershipsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let!(:memberships) { create_list(:membership, 2, user: authorized_user, roles: ["group_admin"]) }
  let(:api_resource_name) { 'memberships' }
  let(:api_resource_attributes) { %w(id state) }
  let(:api_resource_links) { %w(memberships.user memberships.user_group) }

  let(:scopes) { %w(public group) }
  let(:resource) { memberships.first }
  let(:resource_class) { Membership }


  describe "#index" do
    let!(:private_resource) { create(:membership) }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe "#update" do
    let(:test_attr) { :state }
    let(:test_attr_value) { "inactive" }
    let(:update_params) do
      { memberships: { state: "inactive" } }
    end

    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :state }
    let(:test_attr_value) { "inactive" }
    let(:create_params) do
      {
       memberships: {
                     links: {
                             user: create(:user),
                             user_group: resource.user_group
                            }
                    }
      }
    end

    it_behaves_like "is creatable"
  end

  describe "#destroy" do
    let(:instances_to_disable) { [resource] }
    it_behaves_like "is deactivatable"
  end
end
