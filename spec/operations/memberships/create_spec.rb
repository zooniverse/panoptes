require 'spec_helper'

describe Memberships::Create do
  let(:you) { create :user }
  let(:someone) { create :user }
  let(:user_group) { create :user_group }

  it 'is unpermitted for anonymous users' do
    api_user = ApiUser.new(nil)
    expect do
      described_class.run(api_user: api_user, links: {user: someone.id, user_group: user_group.id})
    end.to raise_error(Operation::Unauthenticated)
  end

  describe 'logged in' do
    let(:api_user) { ApiUser.new you }
    let(:operation) { described_class.with(api_user: api_user) }

    describe 'deprecated behaviour' do
      it 'allows you to add someone to a group if you are the group admin' do
        create :membership, user: you, user_group: user_group, roles: ['group_admin']
        result = operation.run links: {user: someone.id, user_group: user_group.id}
        expect(result).to be_valid
        expect(user_group.users).to include(someone)
      end

      it 'allows you to add someone to a group if you are a group member' do
        create :membership, user: you, user_group: user_group, roles: ['group_member']
        result = operation.run links: {user: someone.id, user_group: user_group.id}
        expect(result).to be_valid
        expect(user_group.users).to include(someone)
      end

      it 'allows you to add someone to a group if the group is public' do
        user_group.update! private: false
        result = operation.run links: {user: someone.id, user_group: user_group.id}
        expect(result).to be_valid
        expect(user_group.users).to include(someone)
      end

      it 'disallows you to add anyone to a group if the group is invisible to you' do
        expect do
          operation.run links: {user: someone.id, user_group: user_group.id}
        end.to raise_error(Operation::Unauthorized)
      end
    end

    describe 'with a join token' do
      it 'allows you to add yourself to a group' do
        result = operation.run links: {user: you.id, user_group: user_group.id}, join_token: user_group.join_token
        expect(result).to be_valid
        expect(user_group.users).to include(you)
      end

      it 'disallows you to add someone else to a group' do
        expect do
          operation.run links: {user: someone.id, user_group: user_group.id}, join_token: user_group.join_token
        end.to raise_error(Operation::Unauthorized)
      end

      it 'disallows you to add yourself using the wrong token' do
        expect do
          operation.run links: {user: you.id, user_group: user_group.id}, join_token: 'wrong_token'
        end.to raise_error(Operation::Unauthorized)
      end
    end
  end
end
