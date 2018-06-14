require 'spec_helper'

describe RoledControllerPolicy do
  let(:api_user) { instance_double(ApiUser) }
  let(:resource_class) { User }
  let(:resource_name) { nil }
  let(:action_name) { :index }

  describe '#resources_exist?' do
    let(:user) { create :user }
    let(:api_user) { ApiUser.new(user) }

    it 'returns true when no ids were given' do
      policy = described_class.new(api_user, resource_class, resource_name, action_name, {})
      expect(policy.resources_exist?).to be_truthy
    end

    it 'returns true when resources exist for given ids' do
      user = create(:user)
      params = {id: user.id.to_s}
      policy = described_class.new(ApiUser.new(user), resource_class, resource_name, action_name, params)
      expect(policy.resources_exist?).to be_truthy
    end

    it 'returns false when no resource exists for given id' do
      params = {id: '123'}
      policy = described_class.new(api_user, resource_class, resource_name, action_name, params)
      expect(policy.resources_exist?).to be_falsey
    end
  end

  describe '#resource_ids' do
    it 'returns nil when no ids given' do
      params = {}
      policy = described_class.new(api_user, resource_class, resource_name, action_name, params)
      expect(policy.resource_ids).to eq(nil)
    end

    it 'returns string when given single id' do
      params = {id: '123'}
      policy = described_class.new(api_user, resource_class, resource_name, action_name, params)
      expect(policy.resource_ids).to eq('123')
    end

    it 'returns array of all given ids when given as comma-seperated list' do
      params = {id: '123,456'}
      policy = described_class.new(api_user, resource_class, resource_name, action_name, params)
      expect(policy.resource_ids).to eq(['123', '456'])
    end

    it 'returns subresource parameter ids' do
      params = {"owner_id" => '123,456'}
      policy = described_class.new(api_user, resource_class, 'owner', action_name, params)
      expect(policy.resource_ids).to eq(['123', '456'])
    end
  end

  describe '#scope' do
    it 'returns a scoped query object' do
      scope = double
      expect(api_user).to receive(:scope).with(klass: User,
                                               action: :index,
                                               ids: ["123", "456"],
                                               add_active_scope: false,
                                               context: {login: "foo"})
                            .and_return(scope)

      policy = described_class.new(api_user, resource_class, resource_name, action_name, {id: '123,456'}, scope_context: {login: 'foo'}, add_active_resources_scope: false)
      expect(policy.scope).to eq(scope)
    end
  end
end
