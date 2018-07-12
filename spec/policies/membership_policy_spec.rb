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

      it 'can see other people in public groups' do
        other_user = create :user
        membership1 = create :membership, user: other_user, user_group: public_user_group
        membership2 = create :membership, user: other_user, user_group: private_user_group
        membership3 = create :membership, user_group: public_user_group, state: :inactive

        expect(scope.resolve(:index)).to include(membership1)
        expect(scope.resolve(:show)).to include(membership1)
        expect(scope.resolve(:index)).not_to include(membership2)
        expect(scope.resolve(:show)).not_to include(membership2)
        expect(scope.resolve(:index)).not_to include(membership3)
        expect(scope.resolve(:show)).not_to include(membership3)
      end

      it 'can see who are members of private groups they are in' do
        other_user = create :user
        membership1 = create :membership, user: logged_in_user, user_group: public_user_group
        membership2 = create :membership, user: logged_in_user, user_group: private_user_group
        membership3 = create :membership, user: other_user, user_group: public_user_group
        membership4 = create :membership, user: other_user, user_group: private_user_group

        expect(scope.resolve(:index)).to include(membership1, membership2, membership3, membership4)
        expect(scope.resolve(:show)).to include(membership1, membership2, membership3, membership4)
      end

      it "cannot modify other user's memberships" do
        other_user = create :user
        membership1 = create :membership, user: logged_in_user, user_group: public_user_group
        membership2 = create :membership, user: logged_in_user, user_group: private_user_group
        membership3 = create :membership, user: other_user, user_group: public_user_group
        membership4 = create :membership, user: other_user, user_group: private_user_group

        expect(scope.resolve(:update)).to include(membership1, membership2)
        expect(scope.resolve(:destroy)).to include(membership1, membership2)
        expect(scope.resolve(:update_links)).to include(membership1, membership2)
        expect(scope.resolve(:destroy_links)).to include(membership1, membership2)

        expect(scope.resolve(:update)).not_to include(membership3, membership4)
        expect(scope.resolve(:destroy)).not_to include(membership3, membership4)
        expect(scope.resolve(:update_links)).not_to include(membership3, membership4)
        expect(scope.resolve(:destroy_links)).not_to include(membership3, membership4)
      end
    end

    context 'as the group admin' do
      let(:api_user) { ApiUser.new(group_admin) }

      it 'can access all memberships of the group' do
        membership1 = create :membership, user: logged_in_user, user_group: public_user_group
        membership2 = create :membership, user: logged_in_user, user_group: private_user_group

        expect(scope.resolve(:index)).to include(membership1, membership2)
        expect(scope.resolve(:show)).to include(membership1, membership2)
        expect(scope.resolve(:update)).to include(membership1, membership2)
        expect(scope.resolve(:destroy)).to include(membership1, membership2)
        expect(scope.resolve(:update_links)).to include(membership1, membership2)
        expect(scope.resolve(:destroy_links)).to include(membership1, membership2)
      end
    end
  end
end
