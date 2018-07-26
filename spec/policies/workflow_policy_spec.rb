require 'spec_helper'

describe WorkflowPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project, owner: resource_owner) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_workflow) { build(:workflow, project: public_project) }
    let(:private_workflow) { build(:workflow, project: private_project) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, Workflow).scope_for(:index)
    end

    before do
      public_workflow.save!
      private_workflow.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it "includes workflows from public projects" do
        expect(resolved_scope).to match_array(public_workflow)
      end
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it "includes workflows from public projects" do
        expect(resolved_scope).to match_array(public_workflow)
      end
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it "includes workflows from public projects" do
        expect(resolved_scope).to include(public_workflow)
      end

      it 'includes workflows from owned private projects' do
        expect(resolved_scope).to include(private_workflow)
      end
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'includes everything' do
        expect(resolved_scope).to include(public_workflow, private_workflow)
      end
    end
  end

  describe 'links' do
    let(:resource_owner) { create :user }
    let(:project) { create :project, owner: resource_owner }
    let(:workflow) { create(:workflow, project: project) }
    let(:api_user) { ApiUser.new(resource_owner) }
    let(:policy) { WorkflowPolicy.new(api_user, workflow)}

    it 'allows subject_sets in the same project' do
      subject_set = create(:subject_set, project: project)
      expect(policy.linkable_subject_sets).to match_array([subject_set])
    end
  end
end
