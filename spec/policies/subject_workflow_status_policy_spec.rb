require 'spec_helper'

describe SubjectWorkflowStatusPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project, owner: resource_owner) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_subject_workflow_status) { build(:subject_workflow_status, workflow: build(:workflow, project: public_project)) }
    let(:private_subject_workflow_status) { build(:subject_workflow_status, workflow: build(:workflow, project: private_project)) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, SubjectWorkflowStatus).scope_for(:index)
    end

    before do
      public_subject_workflow_status.save!
      private_subject_workflow_status.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it "includes subject_workflow_statuses from public projects" do
        expect(resolved_scope).to match_array(public_subject_workflow_status)
      end
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it "includes subject_workflow_statuses from public projects" do
        expect(resolved_scope).to match_array(public_subject_workflow_status)
      end
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it "includes subject_workflow_statuses from public projects" do
        expect(resolved_scope).to include(public_subject_workflow_status)
      end

      it 'includes subject_workflow_statuses from owned private projects' do
        expect(resolved_scope).to include(private_subject_workflow_status)
      end
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'includes everything' do
        expect(resolved_scope).to include(public_subject_workflow_status, private_subject_workflow_status)
      end
    end
  end
end
