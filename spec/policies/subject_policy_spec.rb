require 'spec_helper'

describe SubjectPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project, owner: resource_owner) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_subject) { build(:subject, project: public_project) }
    let(:private_subject) { build(:subject, project: private_project) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, Subject).scope_for(:index)
    end

    before do
      public_subject.save!
      private_subject.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it "includes subjects from public projects" do
        expect(resolved_scope).to match_array(public_subject)
      end
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it "includes subjects from public projects" do
        expect(resolved_scope).to match_array(public_subject)
      end
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it "includes subjects from public projects" do
        expect(resolved_scope).to include(public_subject)
      end

      it 'includes subjects from owned private projects' do
        expect(resolved_scope).to include(private_subject)
      end
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'includes everything' do
        expect(resolved_scope).to include(public_subject, private_subject)
      end
    end
  end
end
