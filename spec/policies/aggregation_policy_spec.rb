require 'spec_helper'

describe AggregationPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:project)  { build(:project, owner: resource_owner) }

    let(:public_aggregation) { build(:aggregation, workflow: build(:workflow, project: project, aggregation: {public: true})) }
    let(:private_aggregation) { build(:aggregation, workflow: build(:workflow, project: project)) }

    before do
      public_aggregation.save!
      private_aggregation.save!
    end

    describe 'index' do
      let(:resolved_scope) do
        Pundit.policy!(api_user, Aggregation).scope_for(:index)
      end

      context 'for an anonymous user' do
        let(:api_user) { ApiUser.new(anonymous_user) }

        it "includes aggregations from public projects" do
          expect(resolved_scope).to match_array(public_aggregation)
        end
      end

      context 'for a normal user' do
        let(:api_user) { ApiUser.new(logged_in_user) }

        it "includes aggregations from public projects" do
          expect(resolved_scope).to match_array(public_aggregation)
        end
      end

      context 'for the resource owner' do
        let(:api_user) { ApiUser.new(resource_owner) }

        it "includes aggregations from public projects" do
          expect(resolved_scope).to include(public_aggregation)
        end

        it 'includes aggregations from owned private projects' do
          expect(resolved_scope).to include(private_aggregation)
        end
      end

      context 'for an admin' do
        let(:admin_user) { create :user, admin: true }
        let(:api_user) { ApiUser.new(admin_user, admin: true) }

        it 'includes everything' do
          expect(resolved_scope).to include(public_aggregation, private_aggregation)
        end
      end
    end

    describe 'update' do
      let(:resolved_scope) do
        Pundit.policy!(api_user, Aggregation).scope_for(:update)
      end

      context 'for an anonymous user' do
        let(:api_user) { ApiUser.new(anonymous_user) }

        it "returns nothing" do
          expect(resolved_scope).to be_empty
        end
      end

      context 'for a normal user' do
        let(:api_user) { ApiUser.new(logged_in_user) }

        it "returns nothing" do
          expect(resolved_scope).to be_empty
        end
      end

      context 'for the resource owner' do
        let(:api_user) { ApiUser.new(resource_owner) }

        it "includes aggregations from public projects" do
          expect(resolved_scope).to include(public_aggregation)
        end

        it 'includes aggregations from owned private projects' do
          expect(resolved_scope).to include(private_aggregation)
        end
      end

      context 'for an admin' do
        let(:admin_user) { create :user, admin: true }
        let(:api_user) { ApiUser.new(admin_user, admin: true) }

        it 'includes everything' do
          expect(resolved_scope).to include(public_aggregation, private_aggregation)
        end
      end

    end
  end

  describe 'links' do
    let(:resource_owner) { create(:user) }

    let(:project)  { build(:project, owner: resource_owner) }

    let(:aggregation) { build(:aggregation, workflow: build(:workflow, project: project, aggregation: {public: true})) }

    it 'links against workflows of my projects' do
      workflow1 = create :workflow, project: project
      workflow2 = create :workflow

      expect(policy.linkable_for(:workflow)).to match_array(workflow1)
    end
  end
end
