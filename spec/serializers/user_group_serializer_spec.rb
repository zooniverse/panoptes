require "spec_helper"

RSpec.describe UserGroupSerializer do
  let(:user_group) { create(:user_group) }

  describe 'join token' do
    it 'is serialized when the current user is a group admin' do
      user = create(:user)
      create(:membership, user: user, user_group: user_group, roles: ["group_admin"])

      serialized = described_class.serialize(user_group, current_user: user)
      expect(serialized[:user_groups][0][:join_token]).to eq(user_group.join_token)
    end

    it 'is not serialized otherwise' do
      serialized = described_class.serialize(user_group)
      expect(serialized[:user_groups][0][:join_token]).to be_nil
    end
  end
end
