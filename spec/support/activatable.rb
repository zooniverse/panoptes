shared_examples "activatable" do
  describe "#disable!" do
    it "should change state to inactive" do
      expect(activatable.inactive?).to be_falsy
      activatable.disable!
      expect(activatable.inactive?).to be_truthy
    end
  end

  describe "#enable!" do
    it "should change state to active" do
      activatable.enable!
      expect(activatable.active?).to be_truthy
    end
  end
end
