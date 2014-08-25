require 'spec_helper'

RSpec.describe UserCollectionPreference, :type => :model do
  let(:user_collection) { build(:user_collection_preference) }
  let(:factory) { :user_collection_preference }
  let(:valid_roles)  { ["collaborator"] }
  let(:roles_field) { :roles }

  it 'should have a valid factory' do
    expect(user_collection).to be_valid
  end

  it 'should require a collection to be valid' do
    expect(build(:user_collection_preference, collection: nil)).to_not be_valid
  end

  it 'should require a user to be valid' do
    expect(build(:user_collection_preference, user: nil)).to_not be_valid
  end

  it_behaves_like "roles validated"
end
