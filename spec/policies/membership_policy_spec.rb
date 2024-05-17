require 'spec_helper'

describe MembershipPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:group_admin) { create(:user) }

    let(:public_user_group) { create(:user_group, admin: group_admin, private: false) }
    let(:private_user_group) { create(:user_group, admin: group_admin, private: true) }

    before do
      public_user_group.save!
      private_user_group.save!
    end

    let(:scope) do
      MembershipPolicy::Scope.new(api_user, Membership)
    end

    let(:group_admin_public_membership) { Membership.where(user_id: group_admin.id, user_group_id: public_user_group.id, state: 'active')[0] }
    let(:group_admin_private_membership) {
      Membership.where(user_id: group_admin.id, user_group_id: private_user_group.id, state: 'active')[0]
    }

    context 'an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it 'cannot see any memberships' do
        create :membership, user: logged_in_user, user_group: public_user_group
        create :membership, user: logged_in_user, user_group: private_user_group

        expect(scope.resolve(:index)).to be_empty
      end
    end

    context 'a normal user', :aggregate_failures do
      let(:api_user) { ApiUser.new(logged_in_user) }
      let(:other_user) { create(:user) }
      let(:other_user_public_membership) { create(:membership, user: other_user, user_group: public_user_group) }
      let(:other_user_private_membership) { create(:membership, user: other_user, user_group: private_user_group) }
      let(:logged_in_user_public_membership) { create(:membership, user: logged_in_user, user_group: public_user_group) }
      let(:logged_in_user_private_membership) { create(:membership, user: logged_in_user, user_group: private_user_group) }

      it 'can see other people in public groups' do
        inactive_membership = create :membership, user_group: public_user_group, state: :inactive

        expect(scope.resolve(:index)).to contain_exactly(other_user_public_membership, group_admin_public_membership)
        expect(scope.resolve(:show)).to contain_exactly(other_user_public_membership, group_admin_public_membership)
        expect(scope.resolve(:index)).not_to include(other_user_private_membership)
        expect(scope.resolve(:show)).not_to include(other_user_private_membership)
        expect(scope.resolve(:index)).not_to include(inactive_membership)
        expect(scope.resolve(:show)).not_to include(inactive_membership)
      end

      it 'can see who are members of private groups they are in' do
        expect(scope.resolve(:index)).to contain_exactly(logged_in_user_public_membership, logged_in_user_private_membership, other_user_public_membership, other_user_private_membership, group_admin_public_membership, group_admin_private_membership)
        expect(scope.resolve(:show)).to contain_exactly(logged_in_user_public_membership, logged_in_user_private_membership, other_user_public_membership, other_user_private_membership, group_admin_public_membership, group_admin_private_membership)
      end

      it "cannot modify other user's memberships" do
        expect(scope.resolve(:update)).to include(logged_in_user_public_membership, logged_in_user_private_membership)
        expect(scope.resolve(:destroy)).to include(logged_in_user_public_membership, logged_in_user_private_membership)

        expect(scope.resolve(:update)).not_to include(other_user_private_membership, other_user_public_membership, group_admin_private_membership, group_admin_public_membership)
        expect(scope.resolve(:destroy)).not_to include(other_user_private_membership, other_user_public_membership, group_admin_private_membership, group_admin_public_membership)
      end
    end

    context 'as the group admin' do
      let(:api_user) { ApiUser.new(group_admin) }

      it 'can access all memberships of the group' do
        membership1 = create :membership, user: logged_in_user, user_group: public_user_group
        membership2 = create :membership, user: logged_in_user, user_group: private_user_group

        expect(scope.resolve(:index)).to contain_exactly(membership1, membership2, group_admin_private_membership, group_admin_public_membership)
        expect(scope.resolve(:show)).to contain_exactly(membership1, membership2, group_admin_private_membership, group_admin_public_membership)
        expect(scope.resolve(:update)).to include(membership1, membership2, group_admin_private_membership, group_admin_public_membership)
        expect(scope.resolve(:destroy)).to include(membership1, membership2, group_admin_private_membership, group_admin_public_membership)
      end
    end
  end

  describe "links" do
    let(:user) { create :user }
    let(:api_user) { ApiUser.new(user) }
    let(:membership) { build :membership, user: nil }
    let(:policy) { described_class.new(api_user, membership) }

    it "should allow membership links to any user" do
      expect(policy.linkable_users).to match_array(user)
    end
  end
end
