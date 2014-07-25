require 'spec_helper'

RSpec.describe UserPolicy do
  subject { UserPolicy }

  let(:resource) { build(:user) }

  RSpec.shared_examples "only self" do
    it "should permit admin users" do
      expect(subject).to permit(build(:admin_user), resource)
    end

    it "should permit the user to modify itself" do
      expect(subject).to permit(resource, resource)
    end

    it "should not permit other logged in users" do
      expect(subject).to_not permit(build(:user), resource)
    end

    it "should not permit logged out users" do
      expect(subject).to_not permit(nil, resource)
    end
  end

  permissions :read? do
    it_behaves_like "is public"
  end

  permissions :create? do
    it_behaves_like "is public"
  end

  permissions :update? do
    it_behaves_like "only self"
  end

  permissions :destroy? do
    it_behaves_like "only self"
  end
end
