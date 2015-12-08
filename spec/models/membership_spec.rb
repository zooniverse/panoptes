require 'spec_helper'

describe Membership, :type => :model do
  let(:membership) { create(:membership) }
  it "should have a valid factory" do
    expect(build(:membership)).to be_valid
  end

  describe "#user_group" do
    it "must have a user group" do
      expect(build(:membership, user_group: nil)).to_not be_valid
    end

    it "should belong to a user group" do
      expect(membership.user_group).to be_a(UserGroup)
    end
  end

  describe "::scope_for" do
    let(:memberships) { [create(:membership, state: :active),
                         create(:membership, state: :inactive),
                         create(:membership, state: :invited)] }

    let(:actor) { ApiUser.new(create(:user)) }

    context ":show, :index" do
      it 'should return all a users memberships' do
        actor.user.memberships << memberships
        actor.user.save!

        expect(Membership.scope_for(:show, actor)).to match_array(memberships)
      end

      it 'should return all memberships in a group the user is member of' do
        ug = create(:user_group, private: true)
        ug.memberships << memberships
        membership = ug.memberships.build(user: actor.user, state: :active)
        ug.save!

        memberships.push(membership)
        expect(Membership.scope_for(:show, actor)).to match_array(memberships)
      end

      it 'should return all active memberships of public groups' do
        ug = create(:user_group, private: false)
        ug.memberships << memberships
        ug.save!
        expect(Membership.scope_for(:show, actor)).to match_array([memberships[0]])
      end
    end

    context ":update, :destroy" do
      it 'should return all memberships belonging to the user' do
        actor.user.memberships << memberships
        actor.user.save!

        expect(Membership.scope_for(:update, actor)).to match_array(memberships)
      end

      it 'should return all memmbership belonging to a group the user administrates' do
        ug = create(:user_group, private: true)
        ug.memberships << memberships
        membership = ug.memberships.build(user: actor.user,
                                          state: :active,
                                          roles: ["group_admin"])
        ug.save!

        memberships.push(membership)
        expect(Membership.scope_for(:destroy, actor)).to match_array(memberships)
      end
    end
  end

  describe "#user" do
    it "must have a user" do
      expect(build(:membership, user: nil)).to_not be_valid
    end

    it "should belong to a user" do
      expect(membership.user).to be_a(User)
    end
  end

  describe "#state" do
    it "must have a state" do
      expect(build(:membership, state: nil)).to_not be_valid
    end
  end

  describe "#enable" do
    it "should set state to active" do
      m = membership
      m.enable!
      expect(m.active?).to be_truthy
    end
  end

  describe "#disable" do
    it "should set state to inactive" do
      m = membership
      m.disable!
      expect(m.inactive?).to be_truthy
    end
  end
end
