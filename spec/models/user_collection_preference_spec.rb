require 'spec_helper'

RSpec.describe UserCollectionPreference, :type => :model do
  let(:user_collection) { build(:user_collection_preference) }
  let(:factory) { :user_collection_preference }

  it 'should have a valid factory' do
    expect(user_collection).to be_valid
  end

  it 'should require a collection to be valid' do
    expect(build(:user_collection_preference, collection: nil)).to_not be_valid
  end

  it 'should require a user to be valid' do
    expect(build(:user_collection_preference, user: nil)).to_not be_valid
  end

  describe "#destroy" do
    let(:pref) { create(:user_collection_preference) }
    let(:collection) { pref.collection }

    it "should not cascade delete the relation", :aggregate_failures do
      expect(collection).not_to be_nil
      pref.destroy
      expect(collection.reload).not_to be_nil
    end
  end
end
