shared_examples "is uri nameable" do
  it "should be valid with name" do
    expect(named).to be_valid
  end

  it "should not be valid without name" do
    expect(unnamed).to_not be_valid
  end

  describe "#name" do
    it "should return the uri_name's name" do
      expect(named.uri_name.name).to be(named.name)
    end
  end

  describe "#name=" do
    it "should set uri name if it exists" do
      named.name = "name"
      expect(named.uri_name.name).to eq("name")
    end
  end

  describe "::find_by_name" do
    it "should return the model named by the uri" do
      n = named
      name = n.name
      expect(described_class.find_by_name(name)).to eq(n)
    end
  end

  describe "#to_param" do
    it "should return the resource's name" do
      expect(named.name).to eq(named.to_param)
    end
  end
end
