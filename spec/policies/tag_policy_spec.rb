require 'spec_helper'

describe ProjectPagePolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }

    let(:resolved_scope) do
      Pundit.policy!(api_user, Tag).scope_for(:index)
    end

    let(:api_user) { ApiUser.new(anonymous_user) }

    it "includes all tags" do
      tags = create_list(:tag, 3)
      expect(resolved_scope).to match_array(tags)
    end
  end
end
