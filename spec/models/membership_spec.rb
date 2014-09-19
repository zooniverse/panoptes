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

  describe "#allowed_to_change?" do
    context "a user" do
      let(:user) { ApiUser.new(create(:user)) }

      it 'should be truthy for a user in the membership' do
        membership = create(:membership, user: user.user)
        expect(membership.allowed_to_change?(user)).to be_truthy
      end

      it 'should be falsy for a user not in the membership' do
        membership = create(:membership)
        expect(membership.allowed_to_change?(user)).to be_falsy
      end
    end

    context "a user_group" do
      let(:user_group) { create(:user_group) }
      
      it 'should be truthy for a user in the membership hwne it is active' do
        membership = create(:membership, user_group: user_group, state: :active)
        expect(membership.allowed_to_change?(user_group)).to be_truthy
      end

      it 'should be falsy for a user not in the membership' do
        membership = create(:membership)
        expect(membership.allowed_to_change?(user_group)).to be_falsy
      end

      it 'should be falsy for a user_group in the memberhsip when it is not active' do
        membership = create(:membership, user_group: user_group, state: :inactive)
        expect(membership.allowed_to_change?(user_group)).to be_falsy
      end
    end
  end

  describe "::scope_for" do
    let(:memberships) { [create(:membership, state: :active),
                         create(:membership, state: :inactive),
                         create(:membership, state: :invited)] }
    context "a user actor" do
      it 'should return all memberships' do
        actor = ApiUser.new(create(:user))
        actor.user.memberships << memberships
        actor.user.save!

        expect(Membership.scope_for(:show, actor)).to eq(memberships)
      end
    end

    context "a user_group actor" do
      it 'should return only active memberships' do
        actor = create(:user_group)
        actor.memberships << memberships
        actor.save!

        expect(Membership.scope_for(:show, actor)).to all( be_active )
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
