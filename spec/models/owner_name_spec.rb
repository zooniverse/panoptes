require 'spec_helper'

describe OwnerName, :type => :model do
  it "should have a valid factory" do
    expect(build(:owner_name_for_user)).to be_valid
    expect(build(:owner_name_for_group)).to be_valid
  end

  describe "#resource" do
    it "should not be valid without a resource" do
      expect(build(:owner_name, name: "test")).to_not be_valid
    end

    it "should be able to be user" do
      expect(create(:owner_name_for_user).resource).to be_a(User)
    end

    it "should be able to be a group" do
      expect(create(:owner_name_for_group).resource).to be_a(UserGroup)
    end
  end

  describe "#name" do

    let(:owner_name_factory) { [ :owner_name_for_user, :owner_name_for_group ].sample }

    it "should only create one owner_name" do
      expect{ create(owner_name_factory) }.to change{ OwnerName.count }.from(0).to(1)
    end

    it "should allow a non-duplicate name to be stored" do
      expect(create(owner_name_factory)).to be_a(OwnerName)
    end

    context "when a owner_name already exists" do
      let!(:original) { create(owner_name_factory) }

      it "not allow a duplicate case insensitive name to valid" do
        dup = build(owner_name_factory, name: original.name.upcase)
        expect(dup).to_not be_valid
      end

      it "not have the correct error message on a duplicate case insensitive name" do
        dup = build(owner_name_factory, name: original.name.upcase)
        dup.valid?
        expect(dup.errors[:name]).to include("has already been taken")
      end
    end
  end
end
