shared_examples "is owner nameable" do
  it "should be valid with name" do
    expect(named).to be_valid
  end

  it "should not be valid without name" do
    expect(unnamed).to_not be_valid
  end

  describe "#name" do
    it "should return the owner_name's name" do
      expect(named.owner_name.name).to be(named.name)
    end
  end

  describe "::find_by_name" do
    let!(:persist_the_named_instance) { named.save }

    it "should return nil when searching for nil" do
      find_result = described_class.find_by_name(nil)
      expect(find_result).to be_nil
    end

    it "should return nil when searching for an empty string" do
      find_result = described_class.find_by_name("")
      expect(find_result).to be_nil
    end

    it "should return the model named by the owner" do
      find_result = described_class.find_by_name(named.name)
      expect(find_result).to eq(named)
    end

    it "should return the model named by the owner independent of case" do
      find_result = described_class.find_by_name(named.name.upcase)
      expect(find_result).to eq(named)
    end
  end

  describe "#owner_name" do

    it "should save the owner_name on named resource save" do
      expect{ named.save }.to change{ OwnerName.count }.from(0).to(1)
    end

    it "should destroy the owner_name on named resource destruction" do
      named.save unless named.persisted?
      expect{ named.destroy }.to change{ OwnerName.count }.from(1).to(0)
    end

    it "should not allow an inconsistent resource#uniq_name to owner_name#name" do
      named.owner_name.name = "different"
      named.valid?
      error_attribute = named.send(:model_uniq_name_attribute)
      expect(named.errors[error_attribute]).to include("inconsistent, match the owner_name#name value")
    end

    context "when the owner_name association is blank" do

      before(:each) do
        named.owner_name = nil
      end

      it "should be invalid without a owner_name" do
        expect(named.valid?).to be false
      end

      it "should have the correct error message" do
        named.valid?
        expect(named.errors[:owner_name]).to include("can't be blank")
      end
    end
  end
end
