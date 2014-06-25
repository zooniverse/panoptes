require 'spec_helper'

describe UserGroupPolicy do
  subject { UserGroupPolicy }
  let(:resource) { build(:user_group) }

  shared_examples "allows access for admins or group admins" do
    let(:resource) { create(:user_group) }

    it "should allow admin users" do
      expect(subject).to permit(build(:admin_user), resource)
    end

    it "should allow user group admin" do
      user = build(:user)
      user.add_role :group_admin, resource
      expect(subject).to permit(user, resource)
    end

    it "should not allow access to other users" do
      expect(subject).to_not permit(build(:user), resource)
    end

    it "should not allow non-logged in users" do
      expect(subject).to_not permit(nil, resource)
    end
  end

  permissions :read? do
    it_behaves_like "is public"
  end

  permissions :create? do
    it_behaves_like "is public to logged in users"
  end

  permissions :update? do
    it_behaves_like "allows access for admins or group admins"
  end

  permissions :destroy? do
    it_behaves_like "allows access for admins or group admins"
  end
end
