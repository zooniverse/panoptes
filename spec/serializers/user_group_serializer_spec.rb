# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserGroupSerializer do
  let(:user_group) { create(:user_group) }
  let(:user) { create(:user) }

  describe 'join token' do
    it 'is serialized when the current user is a group admin' do
      create(:membership, user: user, user_group: user_group, roles: ['group_admin'])

      serialized = described_class.serialize(user_group, current_user: user)
      expect(serialized[:user_groups][0][:join_token]).to eq(user_group.join_token)
    end

    it 'is serialized when the current user is a zooniverse admin' do
      admin_user = create(:user, admin: true)

      serialized = described_class.serialize(user_group, current_user: admin_user)
      expect(serialized[:user_groups][0][:join_token]).to eq(user_group.join_token)
    end

    it 'is not serialized when user is a group member' do
      create(:membership, user: user, user_group: user_group, roles: ['group_member'])

      serialized = described_class.serialize(user_group, current_user: user)
      expect(serialized[:user_groups][0][:join_token]).to be_nil
    end

    it 'is not serialized for user not part of group' do
      serialized = described_class.serialize(user_group, current_user: user)
      expect(serialized[:user_groups][0][:join_token]).to be_nil
    end

    it 'is not serialized when there is no current_user' do
      serialized = described_class.serialize(user_group)
      expect(serialized[:user_groups][0][:join_token]).to be_nil
    end
  end
end
