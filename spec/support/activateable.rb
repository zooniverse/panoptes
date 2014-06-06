shared_examples "activateable" do
  describe "#disable" do
    it "should change state to inactive when disabled" do
      example = activateable
      expect(example.inactive?).to be_falsy
      example.disable
      expect(example.inactive?).to be_truthy
    end

    it "should call #enable on all proxied relations" do
      instance = activateable
      instance.class.instance_variable_get(:@activate_proxies).each do |v|
        expect(instance.send(v)).to receive(:disable)
      end
      instance.disable
    end
  end

  describe "#enable" do
    it "should change state to active when enabled" do
      example = activateable
      example.enable
      expect(example.active?).to be_truthy
    end

    it "should call #enable on all proxied relations" do
      instance = activateable
      instance.class.instance_variable_get(:@activate_proxies).each do |v|
        expect(instance.send(v)).to receive(:enable)
      end
      instance.enable
    end
  end
end
