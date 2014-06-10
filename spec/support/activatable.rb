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

  describe "#disabled?" do
    it "should be false when active" do
      activatable.activated_state = :active
      expect(activatable.disabled?).to be false
    end

    it "should be true when inactive" do
      activatable.activated_state = :inactive
      expect(activatable.disabled?).to be true
    end

    it "should be false when nil" do
      activatable.activated_state = nil
      expect(activatable.disabled?).to be false
    end
  end
end
