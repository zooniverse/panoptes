shared_examples "activateable" do
  describe "#disable!" do
    it "should change state to inactive when disabled" do
      example = activateable
      expect(example.inactive?).to be_falsy
      example.disable!
      expect(example.inactive?).to be_truthy
    end
  end

  describe "#enable!" do
    it "should change state to active when enabled" do
      example = activateable
      example.enable!
      expect(example.active?).to be_truthy
    end
  end
end
