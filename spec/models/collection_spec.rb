require 'spec_helper'

describe Collection, :type => :model do
  let(:collection) { create(:collection) }

  it "should have a valid factory" do
    expect(build(:collection)).to be_valid
  end

  describe "#owner" do
    it "must have an owner" do
      expect(build(:collection, owner: nil)).to_not be_valid
    end

    it "should belong to a user owner" do
      expect(collection.owner).to be_a(User)
    end
  end

  describe "#subject" do
    let(:collection) { create(:collection_with_subjects) }

    it "should have many subjects" do
      expect(collection.subjects).to all( be_a(Subject) )
    end
  end
end
