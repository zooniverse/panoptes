shared_examples "is ownable" do
  it "should be valid with an owner" do
    expect(owned).to be_valid
  end

  it "should not be valid without an owner" do
    expect(not_owned).to_not be_valid
  end

  it "should not create an ACL instance when the model is invalid and built" do
    expect{ not_owned }.not_to change{ AccessControlList.count }
  end

  it "should remove the ACL instance when the owned instance is destroyed" do
    owned.save
    expect{ owned.destroy }.to change{ AccessControlList.count }.from(AccessControlList.count).to(AccessControlList.count - 1)
  end

  describe "#owner?" do
    it "should return truthy when passed its owner object" do
      expect(owned.owner?(owned.owner)).to be_truthy
    end

    it "should be falsy when passed an owner that does not own it" do
      not_the_owner = build(:user)
      expect(owned.owner?(not_the_owner)).to be_falsy
    end
  end

  describe "#owner=" do
    let(:new_owner) { create(:user) }
    let!(:old_owner) { owned.owner }

    it "should change the owner of a resource" do
      owned.owner = new_owner
      expect(owned.owner?(new_owner)).to be_truthy
    end

    it "should remove the old owner acl" do
      owned.save
      old_owner_acl = owned.owner_control_list
      owned.owner = new_owner
      expect(owned.owner?(@old_owner)).to be_falsy
      expect{old_owner_acl.reload}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
