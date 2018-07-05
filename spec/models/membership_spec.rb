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
