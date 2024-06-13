require 'spec_helper'

describe AggregationPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }
    let(:collaborator) { create(:user) }

    let(:project) { build(:project, owner: resource_owner) }

    let(:aggregation) { build(:aggregation, workflow: build(:workflow, project: project)) }

    before do
      aggregation.save!
    end

    describe 'index' do
      let(:resolved_scope) do
        Pundit.policy!(api_user, Aggregation).scope_for(:index)
      end

      context 'when the user is an anonymous user' do
        let(:api_user) { ApiUser.new(anonymous_user) }

        it 'returns nothing' do
          expect(resolved_scope).to be_empty
        end
      end

      context 'when the user is a normal user' do
        let(:api_user) { ApiUser.new(logged_in_user) }

        it 'returns nothing' do
          expect(resolved_scope).to be_empty
        end
      end

      context 'when the user is a resource owner' do
        let(:api_user) { ApiUser.new(collaborator) }

        before { create :access_control_list, user_group: collaborator.identity_group, resource: project, roles: ['collaborator'] }

        it 'includes aggregation' do
          expect(resolved_scope).to include(aggregation)
        end
      end

      context 'when the user is a resource collaborators' do
        let(:api_user) { ApiUser.new(resource_owner) }

        it 'includes the aggregation' do
          expect(resolved_scope).to include(aggregation)
        end
      end

      context 'when the user is an admin' do
        let(:admin_user) { create :user, admin: true }
        let(:api_user) { ApiUser.new(admin_user, admin: true) }

        it 'includes the aggregation' do
          expect(resolved_scope).to include(aggregation)
        end
      end
    end

    describe 'update' do
      let(:resolved_scope) do
        Pundit.policy!(api_user, Aggregation).scope_for(:update)
      end

      context 'when the user is an anonymous user' do
        let(:api_user) { ApiUser.new(anonymous_user) }

        it 'returns nothing' do
          expect(resolved_scope).to be_empty
        end
      end

      context 'when the user is a normal user' do
        let(:api_user) { ApiUser.new(logged_in_user) }

        it 'returns nothing' do
          expect(resolved_scope).to be_empty
        end
      end

      context 'when the user is the resource owner' do
        let(:api_user) { ApiUser.new(resource_owner) }

        it 'includes the aggregation' do
          expect(resolved_scope).to include(aggregation)
        end
      end

      context 'when the user is an admin' do
        let(:admin_user) { create :user, admin: true }
        let(:api_user) { ApiUser.new(admin_user, admin: true) }

        it 'includes the aggregation' do
          expect(resolved_scope).to include(aggregation)
        end
      end
    end
  end
end
