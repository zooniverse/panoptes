shared_examples "is an owner" do
  let(:fake_owned) { build(:project) }

  describe "#owns?" do
    it "should return true if it owns an object" do
      expect(owner.owns?(owned)).to be_truthy
    end

    it "should return false if it does not own an object" do
      expect(owner.owns?(fake_owned)).to be_falsy
    end

    it "should return false if the object is not ownable" do
      expect(owner.owns?(OpenStruct.new)).to be_falsy
    end
  end
end
