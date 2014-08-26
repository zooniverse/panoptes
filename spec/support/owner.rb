shared_examples "is an owner" do
  let(:fake_owned) { build(:project) }

  describe "#owns?" do
    it "should return truthy if it owns an object" do
      expect(owner.owns?(owned)).to be_truthy
    end

    it "should return falsy if it does not own an object" do
      expect(owner.owns?(fake_owned)).to be_falsy
    end
  end
end
