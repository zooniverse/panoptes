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
    let!(:persist_the_named_instance) { named.save }

    it "should return the model named by the uri" do
      n = named
      name = n.name
      expect(described_class.find_by_name(name)).to eq(n)
    end
  end

  describe "#uri_name" do

    it "should save the uri_name on named resource save" do
      expect{ named.save }.to change{ UriName.count }.from(0).to(1)
    end

    it "should destroy the uri_name on named resource destruction" do
      named.save unless named.persisted?
      expect{ named.destroy }.to change{ UriName.count }.from(1).to(0)
    end

    context "when the uri_name association is blank" do

      before(:each) do
        named.uri_name = nil
      end

      it "should be invalid without a uri_name" do
        expect(named.valid?).to be false
      end

      it "should have the correct error message" do
        named.valid?
        expect(named.errors[:uri_name]).to include("can't be blank")
      end
    end
  end
end
