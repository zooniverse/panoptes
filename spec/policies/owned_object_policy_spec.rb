require 'spec_helper'

describe OwnedObjectPolicy do
  subject { OwnedObjectPolicy }

  permissions :read? do
    let(:user) { build(:user) }

    context "project is public" do
      let(:resource) { build(:project, visibility: "public") }

      it_behaves_like "is public"
    end

    context "project is private" do
      let(:project) { create(:project, visibility: "private", owner: user) }
      
      it "should permit the owner access" do
        expect(subject).to permit(user, project)
      end

      it "should not permit a non-logged in user" do
        expect(subject).to_not permit(nil, project)
      end

      it "should permit an admin user" do
        expect(subject).to permit(build(:admin_user), project)
      end

      it "should permit a user with the proper role" do
        collab = create(:user)
        collab.add_role :collaborator, project
        expect(subject).to permit(collab, project)
      end
    end
  end

  permissions :create? do
    let(:project) { build(:project) }

    it "should permit the user to create a project" do
      expect(subject).to permit(build(:user), project)
    end

    let(:user) { nil }

    it "should not a permit a non-logged in user to create a project" do
      expect(subject).to_not permit(user, project)
    end
  end

  permissions :update? do
    let(:user) { build(:user) }
    let(:project) { build(:project, owner: user) }

    it "should permit the project owner to update" do
      expect(subject).to permit(user, project)
    end

    it "should permit an admit user to update" do
      expect(subject).to permit(build(:admin_user), project)
    end

    it "should not permit a non-owner user to update" do
      expect(subject).to_not permit(build(:user), project)
    end

    it "should not permit a non-logged in user to update" do
      expect(subject).to_not permit(nil, project)
    end
  end

  permissions :delete? do
    let(:user) { build(:user) }
    let(:project) { build(:project, owner: user) }

    it "should permit the project owner to delete" do
      expect(subject).to permit(user, project)
    end

    it "should permit an admit user to delete" do
      expect(subject).to permit(build(:admin_user), project)
    end

    it "should not permit a non-owner user to delete" do
      expect(subject).to_not permit(build(:user), project)
    end

    it "should not permit a non-logged in user to delete" do
      expect(subject).to_not permit(nil, project)
    end
  end
end
