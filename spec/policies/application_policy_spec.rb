require 'spec_helper'

describe ApplicationPolicy do
  subject { ApplicationPolicy }

  shared_examples "admins only" do
    let(:resource) { build(:subject) }
    it "should allow an admin user to read" do
      expect(subject).to permit(build(:admin_user), resource)
    end

    it "should not allow a non admin user to read" do
      expect(subject).to_not permit(build(:user), resource)
    end

    it "should not allow a non-logged in user to read" do
      expect(subject).to_not permit(nil, resource)
    end
  end

  permissions :read? do
    it_behaves_like "admins only"
  end

  permissions :create? do
    it_behaves_like "admins only"
  end

  permissions :update? do
    it_behaves_like "admins only"
  end

  permissions :destroy? do
    it_behaves_like "admins only"
  end
end
