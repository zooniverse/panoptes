shared_examples "is ownable" do
  it "should be valid with an owner" do
    expect(owned).to be_valid
  end

  it "should not be valid without an owner" do
    expect(not_owned).to_not be_valid
  end

  describe "#to_param" do
    it "should create param consisting of its owner's name and its own name" do
      expect(owned.to_param).to eq("#{owned.owner.name}+#{owned.name}")
    end
  end
end
