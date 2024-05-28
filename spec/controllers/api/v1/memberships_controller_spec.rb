require 'spec_helper'

describe Api::V1::MembershipsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let!(:memberships) { create_list(:membership, 2, user: authorized_user, roles: ["group_admin"], state: :active) }
  let(:api_resource_name) { 'memberships' }
  let(:api_resource_attributes) { %w(id state) }
  let(:api_resource_links) { %w(memberships.user memberships.user_group) }

  let(:scopes) { %w(public group) }
  let(:resource) { memberships.first }
  let(:resource_class) { Membership }

  describe "#index" do
    let!(:private_resource) { create(:membership) }
    let(:n_visible) { 4 }

    before(:each) do
      group = memberships.first.user_group
      create_list(:membership, 2, roles: ["group_member"], state: :invited, user_group: group)
    end

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

    context 'when updating roles as group_admin' do
      let(:other_user) { create(:user) }
      let(:other_user_group) { create(:user_group, admin: authorized_user, private: true) }
      let(:other_user_membership) { create(:membership, user: other_user, user_group: other_user_group, roles: ['group_member']) }

      it 'allows update of membership roles' do
        default_request user_id: authorized_user.id, scopes: scopes
        params = {
          memberships: { roles: ['group_admin'] },
          id: other_user_membership.id
        }

        put :update, params: params
        expect(other_user_membership.reload.roles).to eq(['group_admin'])
      end
    end
  end

  describe "#create" do
    let(:test_attr) { :state }
    let(:test_attr_value) { "active" }
    let(:user_group) { create :user_group }
    let(:create_params) do
      {
        memberships: {
          join_token: user_group.join_token,
          links: {
            user: authorized_user.id.to_s,
            user_group: user_group.id.to_s
          }
        },
      }
    end

    it_behaves_like "is creatable"
  end

  describe "#destroy" do
    let(:instances_to_disable) { [resource] }
    it_behaves_like "is deactivatable"
  end
end
