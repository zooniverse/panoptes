require 'spec_helper'

describe UserSubjectCollection, :type => :model do
  let(:user_subject_collection) { create(:user_subject_collection) }

  it "should have a valid factory" do
    expect(build(:user_subject_collection)).to be_valid
  end

  describe "#owner" do
    it "must have an owner" do
      expect(build(:user_subject_collection, owner: nil)).to_not be_valid
    end

    it "should belong to a user owner" do
      expect(user_subject_collection.owner).to be_a(User)
    end
  end

  describe "#subject" do
    let(:user_subject_collection) { create(:user_subject_collection_with_subjects) }

    it "should have many subjects" do
      expect(user_subject_collection.subjects).to all( be_a(Subject) )
    end
  end
end
