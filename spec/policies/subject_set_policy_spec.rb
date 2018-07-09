require 'spec_helper'

describe SubjectSetPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project, owner: resource_owner) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_subject_set) { build(:subject_set, project: public_project) }
    let(:private_subject_set) { build(:subject_set, project: private_project) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, SubjectSet).scope_for(:index)
    end

    before do
      public_subject_set.save!
      private_subject_set.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it "includes subject sets from public projects" do
        expect(resolved_scope).to match_array(public_subject_set)
      end
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it "includes subject sets from public projects" do
        expect(resolved_scope).to match_array(public_subject_set)
      end
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it "includes subject sets from public projects" do
        expect(resolved_scope).to include(public_subject_set)
      end

      it 'includes subject sets from owned private projects' do
        expect(resolved_scope).to include(private_subject_set)
      end
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'includes everything' do
        expect(resolved_scope).to include(public_subject_set, private_subject_set)
      end
    end
  end

  describe "links" do
    let(:resource_owner) { create :user }
    let(:project) { create(:project, owner: resource_owner) }
    let(:subject_set) { create(:subject_set, num_workflows: 0, project: project) }
    let(:api_user) { ApiUser.new(resource_owner) }
    let(:policy) { SubjectSetPolicy.new(api_user, subject_set)}

    it 'links to workflows the same project' do
      workflow = create :workflow, project: project
      expect(policy.linkable_workflows).to match_array([workflow])
    end

    it 'does not link to workflows in other projects' do
      workflow = create :workflow
      expect(policy.linkable_workflows).to be_empty
    end
  end
end
