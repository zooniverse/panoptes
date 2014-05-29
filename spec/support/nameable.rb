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

    it "should create a new uri name if it doesn't exist" do
      name = named
      old_name_id = name.uri_name.id
      name.uri_name = nil
      name.name = "name1"
      expect(name.uri_name.id).to_not eq(old_name_id)
    end

  end

  describe "::find_by_name" do
    it "should return the model named by the uri" do
      n = named
      name = n.name
      expect(described_class.find_by_name(name)).to eq(n)
    end
  end
end
