require 'spec_helper'

describe RoledControllerPolicy do
  let(:api_user) { instance_double(ApiUser) }
  let(:resource_class) { User }
  let(:action_name) { :index }

  describe '#scope' do
    it 'returns a scoped query object' do
      scope = double
      expect(api_user).to receive(:scope).with(klass: User,
                                               action: :index,
                                               ids: ["123", "456"],
                                               add_active_scope: false,
                                               context: {login: "foo"})
                            .and_return(scope)

      policy = described_class.new(api_user, resource_class, ['123', '456'], scope_context: {login: 'foo'}, add_active_resources_scope: false)
      expect(policy.scope_for(:index)).to eq(scope)
    end
  end
end
